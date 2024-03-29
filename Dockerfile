#
# use ssh+xvfb+xclip+x11vnc as a network-addressible clipboard
#

FROM alpine

# port choices, add em up
# - x11: 6000
# - vnc: 5900
# - ssh: 22
ENV vncport=11900
ENV clipport=11922
ENV clipscreen=99
ENV clipuser=clippy
ENV cliphome=/home/${clipuser}
ENV clipdata=/data/clip

EXPOSE ${clipport}

COPY dropbear.sh /
COPY xvfb.sh /
COPY x11vnc.sh /
COPY startup.sh /
COPY netclip /

RUN chmod 755 /*.sh \
    && apk --no-cache upgrade \
    && apk --no-cache add \
       bash \
       busybox-extras \
       coreutils \
       curl \
       dmenu \
       doas \
       dropbear \
       dropbear-convert \
       dropbear-dbclient \
       dropbear-scp \
       dropbear-ssh \
       dwm \
       file \
       openbox \
       openssh-keygen \
       openssh-sftp-server \
       openssl \
       procps \
       psmisc \
       st \
       sudo \
       tini \
       vim \
       x11vnc \
       xclip \
       xinit \
       xsetroot \
       xterm \
       xvfb \
    && rm -f /bin/sh \
    && ln -s /bin/bash /bin/sh \
    && ln -s /netclip /clip \
    && ln -s /netclip /usr/bin/ \
    && ln -s /netclip /usr/bin/clip \
    && sed -i.ORIG '/^root:/s#/bin/ash#/bin/bash#g' /etc/passwd \
    && mkdir -p /etc/dropbear ${clipdata} \
    && sed -i.ORIG "/^wheel:/s/:root/:root,${clipuser}/g" /etc/group \
    && sed -i "/^shadow:/s/:\$/:${clipuser}/g" /etc/group \
    && echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel \
    && chmod 600 /etc/sudoers.d/wheel \
    && openssl rand -base64 16 > ${clipdata}/passwd \
    && echo ${clipuser} > ${clipdata}/user \
    && echo ${clipport} > ${clipdata}/clipport \
    && echo ${clipscreen} > ${clipdata}/clipscreen \
    && echo ${vncport} > ${clipdata}/vncport \
    && echo "export clipdata=${clipdata}" > /etc/profile.d/clip.sh \
    && addgroup -S ${clipuser} \
    && adduser -D -S -G ${clipuser} -s /bin/bash -h ${cliphome} ${clipuser} \
    && echo "${clipuser}:$(cat ${clipdata}/passwd)" | chpasswd \
    && su - ${clipuser} -c "mkdir -p ${cliphome}/.vnc" \
    && su - ${clipuser} -c "x11vnc -storepasswd '$(cat ${clipdata}/passwd)' ${cliphome}/.vnc/passwd" \
    && echo 'xsetroot -solid darkslategrey' > ${cliphome}/.xinitrc \
    && echo 'exec openbox' >> ${cliphome}/.xinitrc \
    && chmod 755 ${cliphome}/.x* \
    && chown -R ${clipuser}:${clipuser} ${cliphome} ${clipdata} /etc/dropbear \
    && chmod 640 ${clipdata}/* \
    && test -e /etc/motd && cat /etc/motd > /etc/motd.ORIG || true \
    && rm -f /etc/motd || true \
    && cat /etc/doas.conf > /etc/doas.conf.ORIG \
    && echo "permit nopass ${clipuser}" >> /etc/doas.conf

## to debug x11/xvfb/xclip/vnc/x11vnc
#EXPOSE ${vncport}
#RUN openssl rand -base64 16 > ${clipdata}/debug \
#    && adduser -D -S -G wheel -s /bin/bash debug \
#    && echo "debug:$(cat ${clipdata}/debug)" | chpasswd \
#    && chmod 640 ${clipdata}/* \
#    && sed -i '/x11vnc/s/#//g' /startup.sh \
#    && apk --no-cache add font-terminus font-inconsolata font-dejavu font-noto font-noto-cjk font-awesome font-noto-extra

ENTRYPOINT ["/sbin/tini","-gwvv","--"]

CMD ["/startup.sh"]

# vim: set ft=sh:
