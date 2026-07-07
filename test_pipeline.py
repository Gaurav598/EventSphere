import asyncio
from app.db.mongo import connect_to_mongo, get_database
from app.core.identifiers import parse_object_id

async def main():
    await connect_to_mongo()
    db = get_database()
    event_id = "6a4c9c8e5e1eaa3a662c3991"
    event_object_id = parse_object_id(event_id, "event")
    pipeline = [
        {"$match": {"eventId": event_object_id}},
        {
            "$lookup": {
                "from": "users",
                "localField": "userId",
                "foreignField": "_id",
                "as": "user",
            }
        },
        {"$unwind": "$user"},
        {"$sort": {"registeredAt": -1}},
    ]
    cursor = db.registrations.aggregate(pipeline)
    async for document in cursor:
        print(document)

asyncio.run(main())
