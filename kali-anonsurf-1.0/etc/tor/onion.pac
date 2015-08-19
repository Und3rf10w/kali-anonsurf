function FindProxyForURL(url, host)
{
	if (shExpMatch(host,"*.onion"))
	{
		return "SOCKS 127.0.0.1:9050";
	}
	
	if (shExpMatch(host,"*.i2p"))
	{
		return "HTTP 127.0.0.1:4444";
	}
	return "DIRECT";
} 
