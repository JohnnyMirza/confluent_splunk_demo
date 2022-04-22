
import requests
import platform
import logging
import time


__version_tuple__ = (0,0,2)
__version__       = '.'.join(map(str, __version_tuple__))
__email__         = 'NO EMAIL'
__author__        = "Eddie Parra <{0}>".format(__email__)
__copyright__     = "{0}, {1}".format(time.strftime('%Y'), __author__)
__maintainer__    = __author__
__license__       = "BSD"
__status__        = "Alpha"


from .Session import Session
from .AuditLogs import AuditLogs
from .Auth import Auth
from .VpnCredentials import VpnCredentials
from .Locations import Locations
from .User import User
from .Security import Security
from .Ssl import Ssl
from .Activation import Activation
from .Sandbox import Sandbox



logging.basicConfig(level=logging.ERROR, 
	format='%(asctime)s\t%(levelname)s --> %(message)s',
	datefmt='%Y-%m-%d %H:%M:%S'
	) 


class zscaler(Session, Auth, Locations, VpnCredentials, User, Security, Ssl, Activation, Sandbox, AuditLogs): 

	def __init__(self):

		self.session = requests.Session()
		

		# Set Proxies for Reqests 
		#"http”: "http://1.2.3.4:8000”="",
 		#"https”: "http://1.2.3.4:8000",
		self.proxies = {
			"http": "",
 			"https": "",
		}

		self.user_agent = 'ZscalerSDK/%s Python/%s %s/%s' % (
			__version__,
			platform.python_version(),
			platform.system(),
			platform.release()
		)
