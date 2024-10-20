from flask import Flask, request
from flask_restplus import Api, swagger, Resource, Namespace
import flask_restplus
import json,pymongo



class CURD:
    def __init__(self):
        self.client = pymongo.MongoClient('mongodb', 27017)

    def connection(self):
        try:
            self.client = pymongo.MongoClient('mongodb', 27017)
            print(self.client)
        except Exception:
            print("Connection Error")

    def create(self, json_data):
        print(json_data)
        self.client['curd']['c1'].insert_one(json_data)

    def update(self, olds, news):
        print(olds, news)
        query = {"name": olds}
        newvalue = {"$set": {"name": news}}
        result = self.client['curd']['c1'].update_many(query, newvalue)
        return result

    def read(self, id):  # Read Retails of a particular user
        record = self.client['curd']['c1'].find({'id': id}, {'_id': False})
        return record

    def readAll(self):
        records = self.client['curd']['c1'].find({}, {'_id': False})
        return records  # Hare returning Cursor object

    def delete(self, id):
        myquery = {"id": id}
        record = self.client['curd']['c1'].delete_many(myquery)  # Filtering
        print(record.deleted_count)
        return record.deleted_count

app = Flask(__name__)
api = Api(app, version='1.3', title="New Title", description="Its a Hello World App", contact_email='abc@gmail.com')
# NS = Namespace(name="Sample ", description="Description 1")
model1 = api.model("Users", {
    'id': flask_restplus.fields.Integer(required=True, description="Id of the user"),
    'name': flask_restplus.fields.String(required=True, description="Name of User"),
    'age': flask_restplus.fields.Integer(required=False, description="Stores the Age of User")
})
model2 = api.model("List Users", {
    'list_users': flask_restplus.fields.List(flask_restplus.fields.Nested(model1), description="List of Users")
})
SIMPLE_RESPONSE = api.model('simple_response',
                            {
                                'id': flask_restplus.fields.Integer(required=True, description="Id of the user"),
                                'name': flask_restplus.fields.String(required=True, description="Name of the user"),
                                'age': flask_restplus.fields.Integer(required=False,
                                                                     description="Stores the Age of User")
                            }
                            )


@api.route('/create/')
class Language(Resource):
    @api.expect(SIMPLE_RESPONSE, validate=True)  # ?
    def post(self):  # Create
        # data=request.get_json()
        ob = CURD()  # Creating Object of CURDG Class
        ob.create(request.get_json())
        return "Inserted", 201


@api.route('/update/<string:olds>/<string:news>')
class s2(flask_restplus.Resource):
    def put(self, olds, news):
        ob = CURD()  # Creating Object of CURDG Class
        data1 = ob.update(olds, news)  #
        return "Updated", 201


@api.route('/read_all/')
class get_all(Resource):
    def get(self):
        ob = CURD()  # Creating Object of CURDG Class
        data1 = ob.readAll()  # Calling method and storing its cursor object to data
        xx = list(data1)  # Parsing object cursor to list of dictionary
        return xx, 200


@api.route('/read/<int:id>')  # Hare it accpet it as a parameter
class S1(flask_restplus.Resource):
    def get(self, id):
        ob = CURD()
        result = ob.read(id)
        result_list = list(result)
        # print(result_list)
        return result_list


@api.route('/delete/<int:id>')  # Hare it accpet it as a parameter
class S1(flask_restplus.Resource):
    def delete(self, id):
        ob = CURD()
        result = ob.delete(id)
        gg = (str)(result) + " items deleted"
        return gg, 200


if __name__ == '__main__':
    app.run(debug=True,host="0.0.0.0",port=5000)
