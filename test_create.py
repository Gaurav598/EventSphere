import urllib.request
import urllib.parse
import json

url = "http://localhost:8000/api/v1/auth/login"
data = json.dumps({
    "email": "admin@eventsphere.com",
    "password": "Password123!"
}).encode('utf-8')
req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
try:
    with urllib.request.urlopen(req) as res:
        token = json.loads(res.read().decode())["data"]["access_token"]
except urllib.error.HTTPError as e:
    print("Login failed", e.code)
    print(e.read().decode())
    exit(1)

url2 = "http://localhost:8000/api/v1/admin/events"
event_data = {
    "name": "Test Event",
    "description": "Test Description",
    "category": "conference",
    "location": "Test Location",
    "eventDate": "2026-07-08T00:00:00Z",
    "registrationDeadline": "2026-07-08T00:00:00Z",
    "capacity": 100,
    "isPrivate": False
}
req2 = urllib.request.Request(url2, data=json.dumps(event_data).encode('utf-8'), headers={
    "Content-Type": "application/json",
    "Authorization": f"Bearer {token}"
})
try:
    with urllib.request.urlopen(req2) as res2:
        print(res2.status)
        print(res2.read().decode())
except urllib.error.HTTPError as e:
    print(e.code)
    print(e.read().decode())
