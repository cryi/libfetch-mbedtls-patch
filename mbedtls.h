#include <stdlib.h>

#include "fetch.h"
#include "common.h"

int fetch_mbedtls(conn_t *conn, const struct url *URL, int verbose, int permissive);
int fetch_mbedtls_close();