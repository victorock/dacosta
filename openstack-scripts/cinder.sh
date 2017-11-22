keystone service-create --�name cinder --type volume --description "OpenStack Block Storage"
keystone service-create --�name cinderv2 --type volumev2 --description "OpenStack Block Storage"


keystone endpoint-create --service-id \
$(keystone service-list | awk '/volume/ { print $2 }') \
--public-url http://Controller:8776/v1/%\(tenant_id\)s \
--internal-url http://Controller:8776/v1/%\(tenant_id\)s \
--admin-url http://Controller:8776/v1/%\(tenant_id\)s \
--region regionOne

keystone endpoint-create --service-id \
$(keystone service-list | awk '/volume/ { print $2 }') \
--public-url http://Controller:8776/v2/%\(tenant_id\)s \
--internal-url http://Controller:8776/v2/%\(tenant_id\)s \
--admin-url http://Controller:8776/v2/%\(tenant_id\)s \
--region regionOne


apt-get install cinder-api \
cinder-scheduler python-cinderclient -y

crudini --set /etc/cinder/cinder.conf database connection mysql://cinder:roipass@Controller/cinder
crudini --set /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
crudini --set /etc/cinder/cinder.conf DEFAULT rabbit_host Controller
crudini --set /etc/cinder/cinder.conf DEFAULT rabbit_password roipass
crudini --set /etc/cinder/cinder.conf DEFAULT my_ip 11.0.0.41
crudini --set /etc/cinder/cinder.conf DEFAULT glance_host Controller
crudini --set /etc/cinder/cinder.conf DEFAULT verbose True
crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone

crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://Controller:5000/v2.0
crudini --set /etc/cinder/cinder.conf keystone_authtoken identity_uri http://Controller:35357
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_user cinder
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_password roipass

crudini --del /etc/cinder/cinder.conf ​auth_host
crudini --del /etc/cinder/cinder.conf ​​​auth_port
crudini --del /etc/cinder/cinder.conf ​auth_protocol​


su -s /bin/sh -c "cindermanage db sync" cinder
rm -f /var/lib/cinder/cinder.sqlite

service cinder-scheduler restart
service cinder-api restart
