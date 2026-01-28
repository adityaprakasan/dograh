"""
Common utilities.
Shared functions used across the application.
"""

import os

from loguru import logger
from urllib.parse import urlparse, urlunparse
from api.utils.tunnel import TunnelURLProvider


async def get_backend_endpoints() -> tuple[str, str]:
    """
    Get the backend endpoint URLs for external access (webhooks, callbacks, WebSocket connections).
    
    Priority:
        1. BACKEND_API_ENDPOINT environment variable (if set and not localhost)
        2. Cloudflared Tunnel URLs (fallback for localhost or missing env var)
        
    Protocol Handling:
        1. If URL has http:// - returns http:// and ws://
        2. If URL has https:// - returns https:// and wss://
        3. If URL has no protocol - defaults to http:// and ws://
        
    Returns:
        tuple[str, str]: (backend_endpoint, wss_backend_endpoint)
        
    Raises:
        ValueError: If no endpoint URL can be determined or URL is invalid
    """
    # First priority: Check environment variable
    env_endpoint = os.getenv("BACKEND_API_ENDPOINT")
    
    if env_endpoint:
        logger.debug(f"Processing BACKEND_API_ENDPOINT from environment: {env_endpoint}")
        
        # Handle localhost special case - use tunnel URL instead
        if "localhost" in env_endpoint:
            logger.debug(f"BACKEND_API_ENDPOINT is localhost ({env_endpoint}), using tunnel URL instead")
            # Second priority: Query cloudflared tunnel URL
            return await TunnelURLProvider.get_tunnel_urls()
        
        try:
            # Parse the URL to validate and handle protocol
            parsed = urlparse(env_endpoint)
            
            if parsed.scheme:
                # Case 1: URL has protocol (http or https) - use as is
                if parsed.scheme in ['http', 'https']:
                    http_url = urlunparse((
                        parsed.scheme,     # Keep original protocol
                        parsed.netloc,
                        parsed.path,
                        parsed.params,
                        parsed.query,
                        parsed.fragment,
                    ))
                    # Create WebSocket equivalent
                    ws_scheme = 'wss' if parsed.scheme == 'https' else 'ws'
                    ws_url = urlunparse((
                        ws_scheme,         # WebSocket protocol
                        parsed.netloc,
                        parsed.path,
                        parsed.params,
                        parsed.query,
                        parsed.fragment,
                    ))
                else:
                    # Invalid protocol
                    raise ValueError(f"Invalid protocol '{parsed.scheme}' in BACKEND_API_ENDPOINT: '{env_endpoint}'. Only 'http' and 'https' are supported.")
            else:
                # Case 2: No protocol provided - default to http
                # For scheme-less URLs like "api.example.com", the domain is in parsed.path
                domain = parsed.netloc or parsed.path
                
                if not domain:
                    raise ValueError(f"Invalid BACKEND_API_ENDPOINT: '{env_endpoint}' - missing hostname")
                
                http_url = urlunparse((
                    'http',            # Default protocol
                    domain,            # Use domain from netloc or path
                    '',                # Clear path since domain was in path
                    '',                # Clear params
                    '',                # Clear query  
                    '',                # Clear fragment
                ))
                ws_url = urlunparse((
                    'ws',              # Default WebSocket protocol
                    domain,            # Use domain from netloc or path
                    '',                # Clear path since domain was in path
                    '',                # Clear params
                    '',                # Clear query
                    '',                # Clear fragment
                ))
            
            logger.debug(f"Returning backend URLs - HTTP: {http_url}, WebSocket: {ws_url}")
            return http_url, ws_url
            
        except Exception as e:
            # Case 4: Invalid URL format
            raise ValueError(f"Invalid BACKEND_API_ENDPOINT format: '{env_endpoint}' - {str(e)}")
    
    # Second priority: Query cloudflared tunnel URL when no environment variable is set
    logger.debug("No BACKEND_API_ENDPOINT set, using tunnel URL")
    return await TunnelURLProvider.get_tunnel_urls()