/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */
#ifndef INCLUDE_stransport_stream_h__
#define INCLUDE_stransport_stream_h__

//Add by vdh for SSL client-server mutual auth on OSX and iOS ONLY
#ifdef GIT_SECURE_TRANSPORT
#include <CoreFoundation/CoreFoundation.h>
#endif

#include "git2/sys/stream.h"

extern int git_stransport_stream_new(git_stream **out, const char *host, const char *port, CFArrayRef clientCertRef);

#endif
