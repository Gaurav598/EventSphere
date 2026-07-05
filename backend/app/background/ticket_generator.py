import qrcode
import base64
import json
from io import BytesIO
from bson import ObjectId
from app.db.mongo import get_database
from app.models.ticket import TicketInDB
from app.exceptions.handlers import AppException

async def generate_ticket_for_registration(registration_id: str):
    db = get_database()
    
    # Check if ticket already exists
    existing_ticket = await db.tickets.find_one({"registrationId": ObjectId(registration_id)})
    if existing_ticket:
        return
        
    registration = await db.registrations.find_one({"_id": ObjectId(registration_id)})
    if not registration:
        return
        
    # Generate QR Payload
    payload = {
        "registrationId": str(registration["_id"]),
        "eventId": str(registration["eventId"]),
        "userId": str(registration["userId"])
    }
    payload_str = json.dumps(payload)
    
    # Generate QR Code Image
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(payload_str)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    
    # Save as base64 string
    buffered = BytesIO()
    img.save(buffered, format="PNG")
    img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")
    
    qr_image_ref = f"data:image/png;base64,{img_str}"
    
    new_ticket = TicketInDB(
        registrationId=ObjectId(registration_id),
        qrPayload=payload_str,
        qrImageRef=qr_image_ref
    )
    
    ticket_dict = new_ticket.model_dump(by_alias=True, exclude={"id"})
    await db.tickets.insert_one(ticket_dict)
