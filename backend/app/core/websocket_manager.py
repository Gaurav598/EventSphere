from fastapi import WebSocket
from typing import List
import json
import logging

logger = logging.getLogger(__name__)

class ConnectionManager:
    def __init__(self):
        # A list of active websocket connections
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        logger.info(f"WebSocket connected. Total active connections: {len(self.active_connections)}")

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
            logger.info(f"WebSocket disconnected. Total active connections: {len(self.active_connections)}")

    async def broadcast(self, message: dict):
        """
        Best-effort broadcast to all connected clients.
        Failure to send to one client won't break the loop or the caller.
        """
        if not self.active_connections:
            return
            
        message_str = json.dumps(message)
        disconnected_clients = []
        
        for connection in self.active_connections:
            try:
                await connection.send_text(message_str)
            except Exception as e:
                logger.warning(f"Failed to send websocket message: {e}")
                disconnected_clients.append(connection)
                
        # Clean up any broken connections
        for connection in disconnected_clients:
            self.disconnect(connection)

# Global manager instance
manager = ConnectionManager()
