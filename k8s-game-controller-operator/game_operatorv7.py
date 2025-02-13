import kopf
import kubernetes
from kubernetes import client, config
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Kubernetes configuration
try:
    config.load_incluster_config()
    logger.info("Using in-cluster configuration")
except config.ConfigException:
    config.load_kube_config()
    logger.info("Using local kubeconfig configuration")

# Create Kubernetes API clients
api = client.AppsV1Api()

def create_deployment_object(name, namespace):
    """Create a deployment object for the given name"""
    
    # Container template
    container = client.V1Container(
        name=name,
        image="nginx:latest",
        ports=[client.V1ContainerPort(container_port=80)]
    )

    # Pod template
    template = client.V1PodTemplateSpec(
        metadata=client.V1ObjectMeta(labels={"app": name}),
        spec=client.V1PodSpec(containers=[container])
    )

    # Deployment spec
    spec = client.V1DeploymentSpec(
        replicas=1,
        selector=client.V1LabelSelector(
            match_labels={"app": name}
        ),
        template=template
    )

    # Deployment
    deployment = client.V1Deployment(
        api_version="apps/v1",
        kind="Deployment",
        metadata=client.V1ObjectMeta(
            name=name,
            namespace=namespace,
            labels={"app": name},
            # Add owner reference annotation to track deployment
            annotations={"game-controller/owned-by": f"{name}"}
        ),
        spec=spec
    )

    return deployment

@kopf.on.create('mygames.com', 'v1', 'games')
def create_fn(spec, name, namespace, logger, **kwargs):
    """Handler for game resource creation"""
    
    logger.info(f"Creating deployment for game {name}")
    deployment = create_deployment_object(name, namespace)
    
    try:
        api.create_namespaced_deployment(
            namespace=namespace,
            body=deployment
        )
        logger.info(f"Created deployment {name} successfully")
    except kubernetes.client.rest.ApiException as e:
        logger.error(f"Failed to create deployment: {e}")
        raise kopf.PermanentError(f"Failed to create deployment: {e}")

@kopf.on.delete('mygames.com', 'v1', 'games')
def delete_fn(spec, name, namespace, logger, **kwargs):
    """Handler for game resource deletion"""
    
    logger.info(f"Deleting deployment for game {name}")
    try:
        api.delete_namespaced_deployment(
            name=name,
            namespace=namespace
        )
        logger.info(f"Deleted deployment {name} successfully")
    except kubernetes.client.rest.ApiException as e:
        if e.status != 404:  # Ignore if already deleted
            logger.error(f"Failed to delete deployment: {e}")

@kopf.on.resume('mygames.com', 'v1', 'games')
@kopf.timer('mygames.com', 'v1', 'games', interval=5.0)
def reconcile_fn(spec, name, namespace, logger, **kwargs):
    """Handler for reconciliation and periodic checks"""
    
    try:
        # Check if deployment exists
        api.read_namespaced_deployment(name=name, namespace=namespace)
        logger.info(f"Deployment {name} exists")
    except kubernetes.client.rest.ApiException as e:
        if e.status == 404:
            # Deployment doesn't exist, recreate it
            logger.info(f"Deployment {name} not found, recreating")
            deployment = create_deployment_object(name, namespace)
            try:
                api.create_namespaced_deployment(
                    namespace=namespace,
                    body=deployment
                )
                logger.info(f"Recreated deployment {name} successfully")
            except kubernetes.client.rest.ApiException as create_error:
                logger.error(f"Failed to recreate deployment: {create_error}")
        else:
            logger.error(f"Error checking deployment: {e}")

if __name__ == "__main__":
    kopf.run()

