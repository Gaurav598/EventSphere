import logging

from pymongo import ASCENDING, TEXT, AsyncMongoClient, IndexModel

from app.core.config import settings

logger = logging.getLogger(__name__)


class MongoDB:
    client: AsyncMongoClient | None = None
    db = None


db = MongoDB()


async def create_indexes() -> None:
    database = get_database()
    await database.users.create_indexes(
        [IndexModel([("email", ASCENDING)], unique=True, name="users_email_unique")]
    )
    await database.events.create_indexes(
        [
            IndexModel([("eventDate", ASCENDING)], name="events_event_date"),
            IndexModel([("category", ASCENDING)], name="events_category"),
            IndexModel([("location", ASCENDING)], name="events_location"),
            IndexModel(
                [("name", TEXT), ("description", TEXT)],
                name="events_name_description_text",
            ),
        ]
    )
    await database.registrations.create_indexes(
        [
            IndexModel(
                [("userId", ASCENDING), ("eventId", ASCENDING)],
                unique=True,
                name="registrations_user_event_unique",
            ),
            IndexModel([("eventId", ASCENDING)], name="registrations_event"),
        ]
    )
    await database.tickets.create_indexes(
        [
            IndexModel(
                [("registrationId", ASCENDING)],
                unique=True,
                name="tickets_registration_unique",
            )
        ]
    )


async def connect_to_mongo() -> None:
    logger.info("Connecting to MongoDB...")
    db.client = AsyncMongoClient(
        settings.MONGO_URI,
        serverSelectionTimeoutMS=settings.MONGO_CONNECT_TIMEOUT_SECONDS * 1000,
        tz_aware=True,
    )
    await db.client.admin.command("ping")
    db.db = db.client[settings.MONGO_DB_NAME]
    await create_indexes()
    logger.info("Connected to MongoDB")


async def close_mongo_connection() -> None:
    logger.info("Closing MongoDB connection...")
    if db.client is not None:
        await db.client.close()
    db.client = None
    db.db = None
    logger.info("MongoDB connection closed")


def get_database():
    if db.db is None:
        raise RuntimeError("MongoDB has not been initialized")
    return db.db
