from flask import Flask, render_template
import psutil

app = Flask(__name__)

# Helper function to convert bytes to megabytes
def bytes_to_mb(size_bytes):
    return round(size_bytes / (1024 * 1024), 2)

@app.route('/metrics/cpu')
def cpu_metrics():
    cpu_percent = psutil.cpu_percent(interval=1)
    cpu_count = psutil.cpu_count()
    cpu_info = {
        'percent': f"{cpu_percent}%",
        'count': cpu_count
    }
    return render_template('cpu_metrics.html', cpu=cpu_info)

@app.route('/metrics/memory')
def memory_metrics():
    memory_info = psutil.virtual_memory()
    memory_data = {
        'total_MB': bytes_to_mb(memory_info.total),
        'used_MB': bytes_to_mb(memory_info.used),
        'free_MB': bytes_to_mb(memory_info.free)
    }
    return render_template('memory_metrics.html', memory=memory_data)

@app.route('/metrics/disk')
def disk_metrics():
    disk_usage = psutil.disk_usage('/')
    disk_data = {
        'total_MB': bytes_to_mb(disk_usage.total),
        'used_MB': bytes_to_mb(disk_usage.used),
        'free_MB': bytes_to_mb(disk_usage.free)
    }
    return render_template('disk_metrics.html', disk=disk_data)

@app.route('/metrics/network')
def network_metrics():
    network_info = psutil.net_io_counters()
    system_wide = {
        'bytes_sent_MB': bytes_to_mb(network_info.bytes_sent),
        'bytes_recv_MB': bytes_to_mb(network_info.bytes_recv),
        'packets_sent': network_info.packets_sent,
        'packets_recv': network_info.packets_recv
    }
    
    net_per_interface = psutil.net_io_counters(pernic=True)
    interface_stats = {
        interface: {
            'bytes_sent_MB': bytes_to_mb(stats.bytes_sent),
            'bytes_recv_MB': bytes_to_mb(stats.bytes_recv),
            'packets_sent': stats.packets_sent,
            'packets_recv': stats.packets_recv
        } for interface, stats in net_per_interface.items()
    }
    
    network_data = {
        'system_wide': system_wide,
        'per_interface': interface_stats
    }
    return render_template('network_metrics.html', network=network_data)

@app.route('/metrics')
def all_metrics():
    cpu_percent = psutil.cpu_percent(interval=1)
    cpu_count = psutil.cpu_count()
    
    memory_info = psutil.virtual_memory()
    memory_data = {
        'total_MB': bytes_to_mb(memory_info.total),
        'used_MB': bytes_to_mb(memory_info.used),
        'free_MB': bytes_to_mb(memory_info.free)
    }
    
    disk_usage = psutil.disk_usage('/')
    disk_data = {
        'total_MB': bytes_to_mb(disk_usage.total),
        'used_MB': bytes_to_mb(disk_usage.used),
        'free_MB': bytes_to_mb(disk_usage.free)
    }
    
    network_info = psutil.net_io_counters()
    network_data = {
        'system_wide': {
            'bytes_sent_MB': bytes_to_mb(network_info.bytes_sent),
            'bytes_recv_MB': bytes_to_mb(network_info.bytes_recv),
            'packets_sent': network_info.packets_sent,
            'packets_recv': network_info.packets_recv
        },
        'per_interface': {
            interface: {
                'bytes_sent_MB': bytes_to_mb(stats.bytes_sent),
                'bytes_recv_MB': bytes_to_mb(stats.bytes_recv),
                'packets_sent': stats.packets_sent,
                'packets_recv': stats.packets_recv
            } for interface, stats in psutil.net_io_counters(pernic=True).items()
        }
    }
    
    metrics = {
        'cpu': {'percent': f"{cpu_percent}%", 'count': cpu_count},
        'memory': memory_data,
        'disk': disk_data,
        'network': network_data
    }
    return render_template('metrics.html', metrics=metrics)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

