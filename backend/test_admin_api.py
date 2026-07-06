import asyncio
from app.services.admin_service import AdminService
import app.db.mongo as mongo
from motor.motor_asyncio import AsyncIOMotorClient

async def main():
    mongo.client = AsyncIOMotorClient("mongodb://127.0.0.1:27017")
    mongo.db = mongo.client["eventsphere"]
    res = await AdminService.get_event_registrations("6a4ba7325948037e2c9d98dd")
    print(res)

asyncio.run(main())
