from flask import Flask, request, jsonify
from flask_restx import Api, Resource, fields
import pymysql
import os
from datetime import datetime

# Database connection class
class CURD:
    def __init__(self):
        self.connect_to_db()

    def connect_to_db(self):
        try:
            self.conn = pymysql.connect(
                host=os.getenv('MYSQL_HOST', 'mysql'),
                user=os.getenv('MYSQL_USER', 'root'),
                password=os.getenv('MYSQL_PASSWORD', 'password'),
                db=os.getenv('MYSQL_DATABASE', 'curd'),
                cursorclass=pymysql.cursors.DictCursor
            )
            self.cursor = self.conn.cursor()
            print("Connected to MySQL")
        except pymysql.MySQLError as e:
            print(f"MySQL connection error: {e}")
            raise e  # Raise the error to handle it at the application level

    def execute_with_retry(self, query, params, commit=False):
        for attempt in range(3):  # Retry up to 3 times
            try:
                self.cursor.execute(query, params)
                if commit:
                    self.conn.commit()
                return
            except pymysql.OperationalError as e:
                if e.args[0] == 1205:  # Lock wait timeout
                    print(f"Lock wait timeout, retrying... {attempt + 1}/3")
                    self.conn.rollback()  # Rollback if there's a lock wait timeout
                    continue  # Retry the transaction
                else:
                    print(f"Error executing query: {e}")
                    self.conn.rollback()  # Rollback for other OperationalErrors
                    raise  # Reraise unexpected errors
        raise Exception("Failed to execute query after retries")

    def create(self, json_data):
        query = "INSERT INTO users (id, name, age) VALUES (%s, %s, %s)"
        self.execute_with_retry(query, (json_data['id'], json_data['name'], json_data['age']), commit=True)

    def update(self, olds, news):
        query = "UPDATE users SET name=%s WHERE name=%s"
        self.execute_with_retry(query, (news, olds), commit=True)
        return {"message": "User updated"}, 200  # Return success response

    def read(self, id):
        query = "SELECT * FROM users WHERE id=%s"
        self.cursor.execute(query, (id,))
        result = self.cursor.fetchall()
        return self.serialize_datetime(result)

    def readAll(self):
        query = "SELECT * FROM users"
        self.cursor.execute(query)
        results = self.cursor.fetchall()
        return self.serialize_datetime(results)

    def delete(self, id):
        query = "DELETE FROM users WHERE id=%s"
        self.execute_with_retry(query, (id,), commit=True)
        return self.cursor.rowcount

    def serialize_datetime(self, data):
        """Converts datetime fields in the result to string."""
        for record in data:
            for key, value in record.items():
                if isinstance(value, datetime):
                    record[key] = value.isoformat()  # Convert datetime to ISO 8601 string
        return data

# Flask application setup
app = Flask(__name__)
api = Api(app, version='1.3', title="MySQL CRUD App", description="A simple CRUD API using Flask and MySQL")

# API models
model_user = api.model("User", {
    'id': fields.Integer(required=True, description="User ID"),
    'name': fields.String(required=True, description="User Name"),
    'age': fields.Integer(required=False, description="User Age")
})

# CRUD endpoints
@api.route('/create/')
class CreateUser(Resource):
    @api.expect(model_user, validate=True)
    def post(self):
        curd = CURD()
        curd.create(request.json)
        return {"message": "User created"}, 201

@api.route('/update/<string:olds>/<string:news>')
class UpdateUser(Resource):
    def put(self, olds, news):
        curd = CURD()
        return curd.update(olds, news)

@api.route('/read_all/')
class ReadAllUsers(Resource):
    def get(self):
        curd = CURD()
        data = curd.readAll()
        return jsonify(data)  # Use jsonify to return a proper JSON response

@api.route('/read/<int:id>')
class ReadUser(Resource):
    def get(self, id):
        curd = CURD()
        result = curd.read(id)
        return jsonify(result)  # Use jsonify to return a proper JSON response

@api.route('/delete/<int:id>')
class DeleteUser(Resource):
    def delete(self, id):
        curd = CURD()
        deleted_count = curd.delete(id)
        return {"message": f"{deleted_count} user(s) deleted"}, 200

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=5000)

