#!/bin/bash

echo "==========DNS========="
# reference https://github.com/0dataexpert0/openvpn-client-to-socks5-alpine/blob/master/up.sh

if [ "${PEER_DNS}" != "no" ]; then
	NS=
	DOMAIN=
	SEARCH=
	i=1
	while true ; do
		eval opt=\$foreign_option_${i}
		[ -z "${opt}" ] && break
		if [ "${opt}" != "${opt#dhcp-option DOMAIN *}" ] ; then
			if [ -z "${DOMAIN}" ] ; then
				DOMAIN="${opt#dhcp-option DOMAIN *}"
			else
				SEARCH="${SEARCH}${SEARCH:+ }${opt#dhcp-option DOMAIN *}"
			fi
		elif [ "${opt}" != "${opt#dhcp-option DNS *}" ] ; then
			NS="${NS}nameserver ${opt#dhcp-option DNS *}\n"
		fi
		i=$((${i} + 1))
	done

	if [ -n "${NS}" ] ; then
		DNS="# Generated by openvpn for interface ${dev}\n"
		if [ -n "${SEARCH}" ] ; then
			DNS="${DNS}search ${DOMAIN} ${SEARCH}\n"
		elif [ -n "${DOMAIN}" ]; then
			DNS="${DNS}domain ${DOMAIN}\n"
		fi
		DNS="${DNS}${NS}"
		if [ -x /sbin/resolvconf ] ; then
			printf "${DNS}" | /sbin/resolvconf -a "${dev}"
		else
			# Preserve the existing resolv.conf
			if [ -e /etc/resolv.conf ] ; then
				cp /etc/resolv.conf /etc/resolv.conf-"${dev}".sv
			fi
			printf "${DNS}" > /etc/resolv.conf
			chmod 644 /etc/resolv.conf
		fi
	fi
fi
cat /etc/resolv.conf

echo "==========Route========="
# reference https://github.com/kmahyyg/docker-openvpn-socks5/blob/master/entrypoint.sh

SUBNET=$(ip -o -f inet addr show dev eth0 | awk '{print $4}')
IPADDR=$(echo "${SUBNET}" | cut -f1 -d'/')
GATEWAY=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
eval $(ipcalc -np "${SUBNET}")

ip rule add from "${IPADDR}" table 128
ip route add table 128 to "${NETWORK}/${PREFIX}" dev eth0
ip route add table 128 default via "${GATEWAY}"

echo -e "${NETWORK}/${PREFIX} via ${GATEWAY}\n"


echo "==========soga========="
cd /usr/local/XrayR/
nohup /usr/local/XrayR/XrayR -config /etc/XrayR/config.yml &
exit 0