import asyncio
from app.db.mongo import connect_to_mongo, get_database

async def main():
    await connect_to_mongo()
    db = get_database()
    
    pipeline = [{"$match": {"status": "confirmed"}}]
    
    # Test 1: without await
    try:
        cursor1 = db.registrations.aggregate(pipeline)
        async for doc in cursor1:
            pass
        print("Success without await")
    except Exception as e:
        print(f"Error without await: {type(e).__name__} - {str(e)}")

    # Test 2: with await
    try:
        cursor2 = await db.registrations.aggregate(pipeline)
        async for doc in cursor2:
            pass
        print("Success with await")
    except Exception as e:
        print(f"Error with await: {type(e).__name__} - {str(e)}")

asyncio.run(main())
