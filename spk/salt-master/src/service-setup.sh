PYTHON_DIR="/var/packages/python38/target/bin"
PATH="${SYNOPKG_PKGDEST}/bin:${SYNOPKG_PKGDEST}/env/bin:${PYTHON_DIR}:${PATH}"
VIRTUALENV="${PYTHON_DIR}/python3 -m venv"
PYTHON="${PYTHON_DIR}/python3"
LANGUAGE="env LANG=en_US.UTF-8"
SALT_MASTER="${SYNOPKG_PKGDEST}/env/bin/salt-master"
PID_FILE="${SYNOPKG_PKGDEST}/env/var/run/salt-master.pid"

SERVICE_COMMAND="${SALT_MASTER} -c ${SYNOPKG_PKGDEST}/env/etc/salt -d"

service_postinst ()
{
    # Create a Python virtualenv
    ${VIRTUALENV} --system-site-packages ${SYNOPKG_PKGDEST}/env

    # Install the wheels
    wheelhouse=${SYNOPKG_PKGDEST}/share/wheelhouse
    ${SYNOPKG_PKGDEST}/env/bin/pip install --no-deps --no-index --upgrade --force-reinstall -f ${wheelhouse} ${wheelhouse}/*.whl

    # Patch rsax931.py file to find libcrypto lib
    # (Rely on patch util bundled with python3's busybox)
    ${SYNOPKG_PKGDEST}/bin/patch ${SYNOPKG_PKGDEST}/env/lib/python3.8/site-packages/salt/utils/rsax931.py -i ${SYNOPKG_PKGDEST}/share/rsax931.py.patch

    # Prepare salt-master config in /var/packages/salt-minion/
    ln -s /var/packages/${SYNOPKG_PKGNAME}/etc ${SYNOPKG_PKGDEST}/env/etc
    test -d ${SYNOPKG_PKGDEST}/env/etc/salt || install -m 755 -o sc-${SYNOPKG_PKGNAME} -g ${SYNOPKG_PKGNAME} -d ${SYNOPKG_PKGDEST}/env/etc/salt
    test -d ${SYNOPKG_PKGDEST}/env/etc/salt/master.d || install -m 755 -o sc-${SYNOPKG_PKGNAME} -g ${SYNOPKG_PKGNAME} -d ${SYNOPKG_PKGDEST}/env/etc/salt/master.d
    test -f ${SYNOPKG_PKGDEST}/env/etc/salt/master || install -m 644 -o sc-${SYNOPKG_PKGNAME} -g ${SYNOPKG_PKGNAME} ${SYNOPKG_PKGDEST}/share/master ${SYNOPKG_PKGDEST}/env/etc/salt/master
    test -f ${SYNOPKG_PKGDEST}/env/etc/salt/master.d/02_pidfile.conf || echo "pidfile: ${PID_FILE}" > ${SYNOPKG_PKGDEST}/env/etc/salt/master.d/02_pidfile.conf
    test -f ${SYNOPKG_PKGDEST}/env/etc/salt/master.d/01_rootdir.conf || echo "root_dir: ${SYNOPKG_PKGDEST}/env" > ${SYNOPKG_PKGDEST}/env/etc/salt/master.d/01_rootdir.conf
    test -f ${SYNOPKG_PKGDEST}/env/etc/salt/master.d/03_logging.conf || echo "log_file: udp://localhost:10514" > ${SYNOPKG_PKGDEST}/env/etc/salt/master.d/03_logging.conf
    test -f ${SYNOPKG_PKGDEST}/env/etc/salt/master.d/03_logging.conf || echo "log_level_logfile: info" >> ${SYNOPKG_PKGDEST}/env/etc/salt/master.d/03_logging.conf

    # DSM 6
    set_unix_permissions "${SYNOPKG_PKGDEST}"
    set_unix_permissions "${SYNOPKG_PKGDEST}/env/etc/"
}
