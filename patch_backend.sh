sed -i 's/logger.exception("Unhandled exception"/logger.error(f"Validation error: {exc.errors()}")\n        return JSONResponse/g' backend/app/exceptions/handlers.py
