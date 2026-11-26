# asterisk-parity image — malarinv/asterisk:24.0.0-parity
#
# Multi-stage build on Fedora 42 (matches the deployed base image uid 997).
# The image contains NO configuration and NO credentials: pjsip.conf,
# extensions.conf, rtp.conf, modules.conf, asterisk.conf and logger.conf all
# arrive at runtime via the chart's ConfigMap + secret mounts (Phase 4).
FROM registry.fedoraproject.org/fedora:42 AS build

RUN dnf -y install gcc gcc-c++ make autoconf automake libtool bzip2 patch \
    ncurses-devel libedit-devel jansson-devel sqlite-devel libuuid-devel \
    libxml2-devel openssl-devel libsrtp-devel speex-devel speexdsp-devel \
    libogg-devel libvorbis-devel curl-devel openldap-devel \
 && dnf clean all

COPY . /usr/src/asterisk
WORKDIR /usr/src/asterisk

# Clear the sound/MOH menuselect variables: keeps the build off the Asterisk
# download server; this deployment ships no sound files.
RUN ./bootstrap.sh \
 && ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --with-pjproject-bundled \
 && make menuselect.makeopts \
 && ./menuselect/menuselect --disable BUILD_NATIVE menuselect.makeopts \
 && sed -i 's/-march=native//g' makeopts \
 && sed -i -e 's/MENUSELECT_MOH=.*$/MENUSELECT_MOH=/' \
           -e 's/MENUSELECT_CORE_SOUNDS=.*$/MENUSELECT_CORE_SOUNDS=/' \
           -e 's/MENUSELECT_EXTRA_SOUNDS=.*$/MENUSELECT_EXTRA_SOUNDS=/' \
    menuselect.makeopts \
 && make -j"$(nproc)" \
 && make install DESTDIR=/out \
 && make samples DESTDIR=/out \
 && if [ -d /out/usr/sbin ]; then cp -a /out/usr/sbin/. /out/usr/bin/ && rm -rf /out/usr/sbin; fi \
 && rm -rf /out/var/run

FROM registry.fedoraproject.org/fedora:42

RUN dnf -y install libedit jansson sqlite-libs uuid libxml2 openssl-libs \
    libsrtp speex speexdsp libogg libvorbis curl openldap \
 && dnf clean all \
 && groupadd -g 997 asterisk \
 && useradd -u 997 -g 997 -M -s /sbin/nologin asterisk \
 && mkdir -p /var/lib/asterisk /var/log/asterisk /var/spool/asterisk /run/asterisk \
 && chown -R 997:997 /var/lib/asterisk /var/log/asterisk /var/spool/asterisk /run/asterisk

COPY --from=build /out /

ENTRYPOINT ["/usr/bin/asterisk"]
CMD ["-f", "-vvv"]
