/*
 * Copyright (c) 1998, 1999 Nemeton Pty Ltd (ACN 059 848 485).
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by Nemeton Pty Ltd.
 * 4. Neither the name Nemeton Pty Ltd nor the names of the authors
 *    of this software may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY NEMETON PTY LTD ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL NEMETON PTY LTD BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef lint
static const char rcsid[]
#ifdef __GNUC__
__attribute__((__unused__))
#endif
= "$Id: autoreply.c,v 1.33 1999/05/23 20:51:07 giles Exp $";
static const char copyright[]
#ifdef __GNUC__
__attribute__((__unused__))
#endif
= "Copyright (c) Nemeton Pty Ltd 1998, 1999. (ACN 059 848 485).\nAll rights reserved.\n";
#endif /* lint */

#include <sys/param.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <pwd.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sysexits.h>   /* for sendmail exit codes */
#include <time.h>
#include <unistd.h>

#ifndef DEFAULT_COUNT
#define DEFAULT_COUNT 86400
#endif

#ifndef DEFAULT_INTERVAL
#define DEFAULT_INTERVAL 1440
#endif

#ifndef DEFAULT_VACINTERVAL
#define DEFAULT_VACINTERVAL 7
#endif

#ifdef XHEADER
static const char * const Xheader = XHEADER;
#else
static const char * const Xheader = "X-autoreply";
#endif

#ifdef PROGNAME
static const char * const Progname = PROGNAME;
#else
static const char * const Progname = "autoreply";
#endif

/*
 * Options and command line arguments
 */
static int opt_D;
static int count;
static const char *histfile;
static int interval;
static const char *subject_prefix;

/*
 * Global so logentry() can use it easily.
 */

static char *message_id;

/*
 * Portable error codes.  sendmail would let me be much more
 * specific, but there doesn't seem to be much need as we
 * always log errors into the log file.
 *
 * Postfix claims to follow <sysexits.h>.
 *
 * If NEVER_BOUNCE is defined no bounce message will
 * ever be generated via a permanent error return
 * from autoreply.
 */

#define AU_OK 0
#define AU_FAIL 1
#define AU_FAIL_TEMP 2

static const int *exitcode;

#if defined(NEVER_BOUNCE)
static const int sendmail_exit[] = { EX_OK, EX_OK, EX_TEMPFAIL };
static const int qmail_exit[] = { 0, 0, 111 };
#else
static const int sendmail_exit[] = { EX_OK, EX_UNAVAILABLE, EX_TEMPFAIL };
static const int qmail_exit[] = { 0, 100, 111 };
#endif

#define EXIT(x) exit(exitcode[(x < 3 && x >= 0) ? x : 1])

/*
 * logfp is shared between logentry() and openlog()
 */
static FILE *logfp;            /* log file, also used for debug messages */

static void
make_autoreply_dir(const char *path) {
    static int done;
    if (!done && strncmp(path, ".autoreply/", 11) == 0) {
        (void) mkdir(".autoreply", 0700);
        done = 1;
    }
}

/*
 * Log an entry to the log file.
 *
 * If use_stderr is specified, write to stderr as well.  This is
 * complicated by the fact that the log file may be stderr and
 * we don't want two copies in that case.
 *
 * Entries written to stderr are prefixed with "autoreply: ".
 * Entries written to the log file are prefixed with the time in UTC.
 *
 * Errors writing to the log are ignored.
 *
 * The date format matches what syslog wants, so specify /dev/log
 * if you have a syslogd that provides a pipe (aka FIFO, not a Unix
 * domain socket) that you can write to.
 */
static void
logentry(int use_stderr, const char *format, ...)
{
    va_list ap;

    va_start(ap, format);
    if (logfp != (FILE *) 0 && logfp != stderr) {
        time_t now;
        struct tm *time_s;
        char str[17];

        now = time(0);
        time_s = localtime(&now);
        if (strftime(str, sizeof(str), "%b %d %T ", time_s) != 0) {
            if (str[4] == '0')
                str[4] = ' '; /* pity ANSI C didn't standardise %e */
            (void) fputs(str, logfp);
        }
    }
    if (use_stderr || logfp == stderr)
        (void) fprintf(stderr, "%s: ", Progname);
    if (logfp != (FILE *) 0) {
        if (message_id != (char *) 0)
            (void) fprintf(logfp, "msgid=%s ", message_id);
        (void) vfprintf(logfp, format, ap);
        (void) fflush(logfp);
    }
    if (use_stderr && logfp != stderr) {
        if (message_id != (char *) 0)
            (void) fprintf(stderr, "msgid=%s ", message_id);
        (void) vfprintf(stderr, format, ap);
        (void) fflush(stderr);
    }
    va_end(ap);
}

static int
edup2(int oldfd, int newfd)
{
    int ret;
    ret = dup2(oldfd, newfd);
    if (ret == -1) {
        logentry(1, "dup2: %s\n", strerror(errno));
        EXIT(AU_FAIL_TEMP);
    }
    return ret;
}

static FILE *
efopen(const char *path, const char *mode)
{
    FILE *fp;
    fp = fopen(path, mode);
    if (fp == (FILE *) 0) {
        int save_errno;
        save_errno = errno;
        logentry(0, "fopen %s: %s\n", path, strerror(errno));
        EXIT(save_errno == ENFILE ? AU_FAIL_TEMP : AU_FAIL);
    }
    return fp;
}

static void
efprintf(FILE *fp, const char *format, ...)
{
    va_list ap;
    va_start(ap, format);
    if (vfprintf(fp, format, ap) < 0) {
        logentry(0, "write error: %s\n", strerror(errno));
        EXIT(AU_FAIL_TEMP);
    }
}

static void
efstat(int fd, struct stat *bufp, const char * const path)
{
    if (fstat(fd, bufp) == -1) {
        logentry(1, "fstat %s: %s\n", path, strerror(errno));
        EXIT(AU_FAIL);
    }
    return;
}

static void
eftruncate(int fd, off_t length)
{
    if (ftruncate(fd, length) == -1) {
        logentry(1, "ftruncate: %s\n", strerror(errno));
        EXIT(AU_FAIL);
    }
    return;
}

/*
 * Empty signal handler used to timeout fcntl() lock call
 */
/* ARGSUSED */
static void
sigalarm(int n)
{
    ;
}

static void
setup_alarm_handler(void)
{
    struct sigaction act;

    act.sa_handler = sigalarm;
    act.sa_flags = 0;
    if (sigemptyset(&act.sa_mask)) {
        logentry(1, "problem setting empty signal set(!): %s\n",
                 strerror(errno));
        EXIT(AU_FAIL);
    }
    if (sigaction(SIGALRM, &act, (struct sigaction *) 0) == -1) {
        logentry(1, "unable to install signal handler for SIGALRM: %s\n",
                 strerror(errno));
        EXIT(AU_FAIL);
    }
}

static void
elock(int fd)
{
    struct flock fl;

    fl.l_start = 0;
    fl.l_len = 0;
    fl.l_pid = getpid();
    fl.l_type = F_WRLCK;
    fl.l_whence = SEEK_SET;

    setup_alarm_handler();
    (void) alarm(25);
    if (fcntl(fd, F_SETLKW, &fl) == -1) {
        if (errno == EINTR) {
            logentry(0, "timed out trying to lock %s\n", histfile);
            EXIT(AU_FAIL_TEMP);
        } else {
            /* shouldn't happen */
            logentry(1, "error trying to lock %s: %s\n", histfile,
                     strerror(errno));
            EXIT(AU_FAIL);
        }
    }
    (void) alarm(0);
    if (opt_D) logentry(0, "locked history file %s\n", histfile);
    return;
}

void
efseek(FILE *fp, off_t offset, int whence)
{
    if (fseek(fp, offset, whence) == -1) {
        logentry(1, "fseek: %s\n", strerror(errno));
        EXIT(AU_FAIL);
    }
}

static void *
emalloc(size_t n)
{
    void *p;
    p = malloc(n);
    if (p == (void *) 0) {
        logentry(1, "memory allocation failure\n");
        EXIT(AU_FAIL_TEMP);
    }
    return p;
}

static char *
estrdup(const char *s)
{
    char *p;
    p = (char *) emalloc(strlen(s) + 1);
    strcpy(p, s);
    return p;
}

/*
 * Only valid for ASCII; won't work for I18N.
 * For mail headers we don't _want_ to do I18N.
 */
void
strtolower(char *s)
{
    char *p;
    if (s == (char *) 0)
        return;
    for (p = s; *p; p++)
        *p = tolower(*p);
}

static int
strbegin(const char *s1, const char *s2)
{
    if (s1 == (char *) 0 || s2 == (char *) 0)
        return 0;
    return (strncmp(s1, s2, strlen(s2)) == 0);
}

#define streq(s1, s2) (strcmp(s1, s2) == 0)

/*
 * Does s1 end with s2?
 */
static int
strend(const char *s1, const char *s2)
{
    int len1;
    int len2;

    if (s1 == (char *) 0 || s2 == (char *) 0)
        return 0;

    len1 = strlen(s1);
    len2 = strlen(s2);
    if (len1 < len2)
        return 0;
    else if (len1 == len2)
        return streq(s1, s2);
    else
        return streq(&s1[len1 - len2], s2);
}

static void
open_logfile(const char *path)
{
    make_autoreply_dir(path);
    logfp = fopen(path, "a");
    if (logfp == (FILE *) 0) {
        logentry(1, "fopen %s for writing: %s\n", path, strerror(errno));
    } else {
        int fd;
        struct stat statbuf;
        fd = fileno(logfp);
        efstat(fd, &statbuf, path);
        /* try to set append mode on the log file, ignore errors */
        if (S_ISREG(fd) && fcntl(fd, F_SETFL, O_APPEND) == -1)
            logentry(0, "fcntl O_APPEND: %s, continuing\n", strerror(errno));
    }
}

/*
 * Read a line.  Anything beyond BUFSIZ-1 characters is discarded.
 * The trailing \n is discarded.
 */
static char *
readline(FILE *fp)
{
    char *p;
    char *q;
    static char *buf;

    if (buf == (char *) 0)
        buf = (char *) emalloc(BUFSIZ);

    p = fgets(buf, BUFSIZ, fp);
    if (p == (char *) 0) {
        if (ferror(fp)) {
            logentry(0, "fread error: %s\n", strerror(errno));
            EXIT(AU_FAIL_TEMP);
        }
        return (char *) 0;
    }
    q = strchr(p, '\n');
    if (q == (char *) 0) {
        char *buf2;
        buf2 = (char *) emalloc(BUFSIZ);
        do {
            q = fgets(buf2, BUFSIZ, fp);
        } while ((q != (char *) 0) && (strchr(q, '\n') == (char *) 0));
        free(buf2);
    } else {
        *q = '\0';
    }
    return p;
}

/*
 * Read and parse Unix "From " line supplied by sendmail.
 */
static char *
ufline(FILE *fp)
{
    char *p;
    char *q;

    p = readline(fp);
    if (p == (char *) 0 || strncmp(p, "From ", 5) != 0) {
        logentry(1, "No SENDER set in environment and no From line\n");
        EXIT(AU_FAIL);
    }

    /*
     * REVISIT BUG FIX
     *
     * The current code assumes there are no spaces or
     * tabs in the envelope sender, which is bogus,
     * but works well enough for addresses typically
     * seen on the Internet.
     *
     * Full parsing of the envelope address is a can
     * of worms.
     */
    q = strtok(&p[5], " \t\n");
    if (q == (char *) 0) {
        /* can't happen -- we checked for \n above */
        logentry(0, "From line has bad format: %s\n");
        EXIT(AU_FAIL);
    }
    if (strcasecmp(q, "MAILER-DAEMON") == 0)
        return "";
    else
        return estrdup(q);
}

/*
 * For most signals, we'll just let whatever happens happen.
 * Mostly that means there will be a mail bounce, but that
 * doesn't matter too much.
 *
 * While the history file is being updated all signals will
 * have to be blocked to minimise the risk of corrupting
 * the file.
 */
static void
block_signals(int on)
{
    struct sigaction act;
    static struct sigaction oact;

    if (on) {
        if (sigfillset(&act.sa_mask) == -1) {
            logentry(1, "problem filling signal mask: %s\n", strerror(errno));
            EXIT(AU_FAIL);
        }
        if (sigprocmask(SIG_SETMASK, &act.sa_mask, &oact.sa_mask) == -1) {
            logentry(1, "problem setting signal mask: %s\n", strerror(errno));
            EXIT(AU_FAIL);
        }
    } else {
        if (sigprocmask(SIG_SETMASK, &oact.sa_mask, (sigset_t *) 0) == -1) {
            logentry(1, "problem resetting signal mask: %s\n", strerror(errno));
            EXIT(AU_FAIL);
        }
    }
}

/*
 * Check that we're not over the permitted rate, and that
 * we haven't sent mail to this address within the last interval.
 *
 * Only successful deliveries to sendmail are counted.  An argument
 * can be made for counting attempts as more accurately reflecting
 * load on the machine, but we don't do that.
 *
 * RETURNS
 *
 * file pointer for the history file (locked)
 *
 * Leaving this file locked serialises responses from this
 * program and therefore slows througput.  It simplifies
 * the code though, particulary backing out failed updates.
 * In any case it can be changed later if needed.
 *
 * If speedups are sought the history file format should
 * be entirely re-worked, actually.
 */
FILE *
check_history(const char *to)
{
    char *buf;
    char *p;
    int n;
    FILE *fp;
    int ret;
    struct stat statbuf;
    time_t now;
    time_t earliest;

    now = time(0);
    earliest =  now - 60 * interval;

    make_autoreply_dir(histfile);
    fp = efopen(histfile, "a+");
    efseek(fp, 0, SEEK_SET);
    elock(fileno(fp));
    efstat(fileno(fp), &statbuf, histfile);

    /*
     * If the count == 0 (no rate-limiting) then return right away
     */
    if (count == 0) {
        return fp;
    }

    /*
     * If the history file is all old stuff return right away.
     */
    if (earliest > statbuf.st_mtime) {
        if (opt_D) logentry(0, "all history is older than interval\n");
        eftruncate(fileno(fp), 0);
        return fp;
    }
    if (statbuf.st_size == 0) {
        if (opt_D) logentry(0, "zero size history file\n");
        return fp;
    }
    buf = (char *) emalloc(statbuf.st_size + 1);
    ret = fread(buf, 1, statbuf.st_size, fp);
    if (ret < statbuf.st_size) {
        if (ferror(fp)) {
            logentry(1, "%s: read error: %s\n", histfile, strerror(errno));
            EXIT(AU_FAIL);      /* drastic, be we _did_ open it for reading */
        } else {
            /* can't happen */
            logentry(0, "warning: early EOF reading history file %s\n",
                     histfile);
        }
    }
    buf[ret] = '\0';

    /*
     * Meander through the entries until arriving at
     * one that is later than 'earliest'.
     *
     * Each entry is a time_t (in ascii), one tab
     * character, a mail address and a newline.
     */
    if (opt_D)
        logentry(0, "earliest interesting time value is %x\n", earliest);
    p = buf;
    while (p < &buf[ret]) {
        char *p2;
        time_t t;
        p2 = strchr(p, '\t');
        if (p2 != (char *) 0) {
            *p2 = '\0';
            t = strtol(p, (char **) 0, 16);
            if (t >= earliest) {
                if (opt_D) logentry(0,
                                    "found valid time entry %x at offset %d\n",
                                    t, p - buf);
                *p2 = '\t';
                break;
            } else {
                if (opt_D) logentry(0, "ignoring too early time %x\n", t);
            }
            p2 = strchr(p2 + 1, '\n');
            if (p2 != (char *) 0) {
                p = p2 + 1;
            }
        } else {
            /* corrupt file? */
            logentry(0, "%s: possible file corruption\n", histfile);
            p = &buf[ret];
        }
    }

    /*
     * Write out the still current history, and
     * truncate the file to size.
     */
    if (p != buf) {
        int nsize;
        efseek(fp, 0, SEEK_SET);
        block_signals(1);
        if (p < &buf[ret - 1]) {
            nsize = ret - (p - buf);
            if (opt_D) logentry(0, "writing %d bytes of histfile\n", nsize);
            if (fwrite(p, 1, nsize, fp) <  nsize ||
                fflush(fp) == EOF)
            {
                logentry(1, "%s: write error: %s\n", histfile,
                         strerror(errno));
                exit(AU_FAIL_TEMP);
            }
        } else {
            nsize = 0;
        }
        eftruncate(fileno(fp), nsize);
        block_signals(0);
    }

    /*
     * Look through the current history, checking:
     * (a) that this address hasn't been replied to
     * (b) that we aren't over the reply limit
     */
    n = 0;
    while (p < &buf[ret]) {
        char *p2;
        p2 = strchr(p, '\t');
        if (p2 == (char *) 0 || p2 >= &buf[ret])
            break;
        n++;
        p = p2 + 1;
        p2 = strchr(p, '\n');
        if (p2 == (char *) 0 || p2 >= &buf[ret])
            break;
	*p2 = '\0';
        if (strcasecmp(p, to) == 0) {
            logentry(0, "suppressed reply to %s within interval\n", to);
            EXIT(AU_OK);
        }
	*p2++ = '\n';
        p = p2;
    }
    free(buf);

    if (n >= count) {
        logentry(0, "suppressed reply to %s: rate exceeded\n", to);
        EXIT(AU_OK);
    }

    return fp;
}

/*
 * Check that we know who to reply to, that they are not on our
 * list of don't-reply addresses.  check_history() is responsible
 * for deciding if we've talked to them recently.
 */
static void
check_sender(const char *to)
{
    char *p;
    char *q;

    if (to == (char *) 0) {
        logentry(1, "no sender information\n");
        EXIT(AU_FAIL);
    }

    if ((*to == '\0') || streq(to, "#@[]")) {
        logentry(0, "suppress response to bounce address <%s>\n", to);
        EXIT(AU_OK);
    }

    q = p = estrdup(to);
    /*
     * Could use strtolower() and strchr(), but this does
     * it in one pass and only does the start of the string.
     * (Untested whether it is actually faster or not! :-)
     */
    for (; *q != '\0'; q++) {
        if (*q == '@') {
            *q = '\0';
            break;
        }
        *q = tolower(*q);
    }

    /*
     * Would like to read these from a file, but given the problems
     * people have setting up mdforward the less configuration the
     * better.
     */
    if (
        streq(p, "daemon") ||
        streq(p, "listproc") ||
        streq(p, "listserv") ||
        streq(p, "lp") ||
        streq(p, "mailer-daemon") ||
        streq(p, "majordomo") ||
        streq(p, "news") ||
        streq(p, "nobody") ||
        streq(p, "petidomo") ||
        streq(p, "postmaster") ||
        streq(p, "root") ||
        streq(p, "uucp") ||
        strend(p, "-owner") ||
        strend(p, "-request") ||
        /*
         * qmail accounts -- not real users
         */
        streq(p, "alias") ||
        streq(p, "qmaild") ||
        streq(p, "qmaill") ||
        streq(p, "qmailp") ||
        streq(p, "qmailq") ||
        streq(p, "qmailr") ||
        streq(p, "qmails") ||
        /*
         * Wietse Venema's postfix mailer
         */
        streq(p, "postfix") ||
        /*
         * These next two merely for compatibility with vacation(1)
         * -- I'm not sure they're required.
         */
        strend(p, "mailer") ||
        strend(p, "-relay"))
    {
        logentry(0, "disallow response to %s\n", to);
        EXIT(AU_OK);
    }
    free(p);
}

char *
check_headers(FILE *fp)
{
    char *p;
    char *q;
    char *subject;
    char *xheader;

    subject = (char *) 0;
    xheader = estrdup(Xheader);
    strtolower(xheader);

    /*
     * Catch the obvious no-nos based on the incoming message's
     * headers. Ignore errors while reading the message.
     *
     * Better parsing would check that these headers are complete, and
     * are followed by "\s*:" (in perl regex notation).  I've never
     * seen a message with whitespace before the colon in the wild, so
     * ignore the possibility for the moment.
     *
     * REVISIT: this code won't stop at the end of the header
     * if the mail has been through a broken gateway that adds
     * a space to each line.  DJB's recommendation is to stop
     * at the first empty line OR the first line that can't
     * be a header.
     */
    while (((p = readline(fp)) != (char *) 0) && *p != '\n') {
        q = estrdup(p);
        strtolower(q);
        if (strbegin(q, "mailing-list:") ||     /* de-facto standard */
            strbegin(q, xheader)         ||     /* our loop catcher */
            strbegin(q, "list-help:")     ||    /* RFC 2369 */
            strbegin(q, "list-subscribe:") ||   /* RFC 2369 */
            strbegin(q, "list-unsubscribe:") || /* RFC 2369 */
            strbegin(q, "list-post:")    ||     /* RFC 2369 */
            strbegin(q, "list-owner:")   ||     /* RFC 2369 */
            strbegin(q, "list-archive:"))       /* RFC 2369 */
        {
            logentry(0, "disallow reply due to header %s\n", p);
            EXIT(AU_OK);
        }
        if (strbegin(q, "precedence:") &&
            (strstr(q, "bulk") || strstr(q, "list") || strstr(q, "junk")))
        {
            logentry(0, "disallow reply due to value %s\n", p);
            EXIT(AU_OK);
        } else if (strbegin(q, "subject:")) {
            subject = &p[8];
            while (isspace(*subject))
                subject++;
            /* treat an empty subject line the same as a missing one */
            if (*subject == '\0')
                subject = (char *) 0;
            else
                subject = estrdup(subject);
        } else if (strbegin(q, "message-id:")) {
            message_id = &p[11];
            while (isspace(*message_id))
                message_id++;
            if (*message_id == '\0')
                message_id = (char *) 0;
            else
                message_id = estrdup(message_id);
        }
        free(q);
    }
    free(xheader);
    return subject;
}

void
copy(FILE *from, FILE *to)
{
    char *buf;
    int n;

    buf = (char *) emalloc(BUFSIZ);
    while ((n = fread(buf, 1, BUFSIZ, from)) > 0) {
        if (fwrite(buf, 1, n, to) < n) {
            logentry(0, "write error creating response: %s\n",
                     strerror(errno));
            EXIT(AU_FAIL_TEMP);
        }
    }
    if (ferror(from)) {
        logentry(0, "read error reading response file: %s\n",
                 strerror(errno));
        EXIT(AU_FAIL);
    }
    free(buf);
}

/*
 * Build a temporary file with the response in it.
 * When this function returns the temporary file has been
 * unlinked, and the file pointer (and the underlying
 * file descriptor) are positioned at the start of
 * the file.
 */
FILE *
build_response(const char *to, const char *pathname, const char *subject)
{
    FILE *fp;
    FILE *text_fp;
    char *hostname;
    
    /*
     * REVISIT Use of tmpfile() is OK on 4.4BSD derived systems
     * but can be unsafe otherwise.
     */
    fp = tmpfile();
    if (fp == (FILE *) 0) {
        logentry(1, "problem creating temporary file: %s\n", strerror(errno));
        EXIT(AU_FAIL_TEMP);
    }
    efprintf(fp, "To: %s\n", to);
    if (subject_prefix != (char *) 0) {
        if (subject != (char *) 0)
            efprintf(fp, "Subject: %s %s\n", subject_prefix, subject);
        else
            efprintf(fp, "Subject: %s\n", subject_prefix);
    }
    if (message_id != (char *) 0)
        efprintf(fp, "References: %s\n", message_id);
    hostname = (char *) emalloc(MAXHOSTNAMELEN);
    if (gethostname(hostname, MAXHOSTNAMELEN) == 0)
        efprintf(fp, "%s: uid %d at %s\n", Xheader, getuid(), hostname);
    else
        efprintf(fp, "%s: uid %d at amnesiac\n", Xheader, getuid());
    free(hostname);

    make_autoreply_dir(pathname);
    text_fp = efopen(pathname, "r");
    copy(text_fp, fp);
    if (fclose(text_fp) == EOF)
        if (opt_D) logentry(0, "warning: fclose: %s\n", strerror(errno));
    if (fflush(fp) == EOF) {
        logentry(0, "fflush on created message file: %s\n", strerror(errno));
        EXIT(AU_FAIL_TEMP);
    }
    efseek(fp, 0, SEEK_SET);
    /* lseek is paranoid, but we'll exec later before using fp */
    if (lseek(fileno(fp), 0, SEEK_SET) == -1) {
        logentry(0, "lseek on created message file: %s\n", strerror(errno));
        EXIT(AU_FAIL);
    }
    return fp;
}

static const char *
get_home(void)
{
    char *p;
    struct passwd *pwd;

    p = getenv("HOME");
    if ((p != (char *) 0) && *p != '\0')
        return p;

    pwd = getpwuid(getuid());
    if (pwd == (struct passwd *) 0) {
        logentry(1, 
"%s: $HOME not set and can't find password entry for user id %d\n",
                 Progname, getuid());
        EXIT(AU_FAIL);
    }

    return pwd->pw_dir;
}

static const char *locations[] = {
    "/usr/sbin/sendmail",
    "/usr/lib/sendmail",
    (char *) 0
};

static const char *
get_sendmail(void)
{
    const char **p;

    for (p = locations; *p != (char *) 0; p++) {
        if (access(*p, X_OK) == 0)     /* we're not _trusting_ this, OK? */
            break;
    }
    return *p;
}

/*
 * RETURNS
 *
 *  0    OK, reply sent
 * -1    permanent error
 *  1    temporary error
 *
 * This function *first* tries to update the history and then
 * replies.  If the reply fails it attempts to unwind the
 * update in the history file.  If -that- fails, then this
 * person won't get a response again until the interval is
 * up.  Too bad.
 */
void
send_response(const char *recipient, FILE *hfp, FILE *message_fp)
{
    char *p;
    const char *sendmail;
    int pid;
    int ret;
    long offset;

    offset = ftell(hfp);
    if (offset == -1) {
        logentry(0, "ftell on history file failed: %s\n", strerror(errno));
        EXIT(AU_FAIL);
    }
    if (opt_D) logentry(0, "history file offset is: %x\n", offset);
    block_signals(1);
    if (fprintf(hfp, "%08x\t%s\n", (unsigned int) time(0), recipient) < 0 ||
        fflush(hfp) == EOF)
    {
        logentry(0, "write to history file failed: %s\n", strerror(errno));
        EXIT(AU_FAIL_TEMP);
    }
    block_signals(0);

    pid = fork();
    switch (pid) {
    case -1:
        logentry(0, "fork failed: %s\n", strerror(errno));
        /*
         * Undo the history file update
         */
        (void) ftruncate(fileno(hfp), offset);
        EXIT(AU_FAIL_TEMP);
        break;

    case 0:
        edup2(fileno(message_fp), 0);
        if (fclose(message_fp) == EOF) {
            /* very wierd if this fails, so exit */
            logentry(0, "close of temporary file: %s\n", strerror(errno));
            exit(1);
        }
        if (lseek(0, 0, SEEK_SET) == -1) {
            logentry(0, "lseek on standard input: %s\n", strerror(errno));
            exit(1);
        }

        /*
         * real sendmail wants -f <> for an empty envelope sender.
         * Both qmail's and postfix's "sendmail" programs want
         * just -f "".
         *
         * The programs also do different things if left to
         * make up a "From: " line:
         *
         * sendmail: From: MAILER-DAEMON
         * qmail:    From: user@localhost.domain
         * postfix:  From: "" (Real User)
         *
         * It is better to handle this by putting a "From: "
         * line in the text file than by environment variables
         * or more flags here.
         */
        p = getenv("AGENT");
        if ((char *) p != 0 && streq(p, "sendmail"))
            p = "<>";
        else
            p = "";
            
        sendmail = get_sendmail();
        if (sendmail != (char *) 0) {
            execl(sendmail, "sendmail", "-i", "-f", p, recipient, (char *) 0);
        } else {
            sendmail = "sendmail";
            execlp(sendmail, "sendmail", "-i", "-f", p, recipient, (char *) 0);
        }
        logentry(1, "failed to exec %s: %s\n", sendmail, strerror(errno));
        exit(1);        /* not EXIT() or return, this is the child */
        break;

    default:
        (void) waitpid(pid, &ret, 0);
        ret = WEXITSTATUS(ret);
        /* assumes incoming MTA is the one we found as "sendmail" */
        if (ret == exitcode[AU_FAIL_TEMP]) {
            logentry(0, "temporary failure sending mail to <%s>\n", recipient);
            /* back out the history file update */
            (void) ftruncate(fileno(hfp), offset);
            EXIT(AU_FAIL_TEMP);
        } else if (ret != 0) {
            logentry(1, "failed to send mail to <%s>\n", recipient);
            /* back out the history file update */
            (void) ftruncate(fileno(hfp), offset);
            EXIT(AU_FAIL);
        } else {
            logentry(0, "replied to <%s>\n", recipient);
        }
    }
}

static void
usage(void)
{
    fprintf(stderr, "usage: %s [options] file\n", Progname);
    fprintf(stderr, "       -c count      maximum number of messages per interval (default: %d)\n", DEFAULT_COUNT);
    fprintf(stderr, "       -h pathname   path to history file (default: $HOME/.qutoreply/histfile)\n");
    fprintf(stderr, "       -i interval   interval in minutes (default: %d)\n", DEFAULT_INTERVAL);
    fprintf(stderr, "       -l logfile    path to log file (default: $HOME/.autoreply/log)\n");
    fprintf(stderr, "       -s subject    prefix to add to subject when replying\n");
    EXIT(AU_FAIL);
}

void
parse_options(int argc, char *argv[]) {
    int c;

    opterr = 0;
    while ((c = getopt(argc, argv, ":Dc:h:i:l:s:")) != -1) {
        switch (c) {
        case 'D':
            opt_D = 1;
            break;
        case 'c':
            count = atoi(optarg);
            if (count < 0) {
                logentry(0, "bad value %s for count\n", optarg);
                count = DEFAULT_COUNT;
            }
            break;
        case 'h':
            histfile = optarg;
            break;
        case 'i':
            interval = atoi(optarg);
            if (interval <= 0) {
                logentry(0, "bad argument %s to -i: must be positive,\n",
                         optarg);
                interval = DEFAULT_INTERVAL;
            }
            break;
        case 'l':
            if (logfp != (FILE *) 0)
                logentry(0, "-l option seen multiple times, continuing\n");
            else if (*optarg != '\0')
                open_logfile(optarg);
            else
                logentry(0, "bad argument to -l option\n");
            break;
        case 's':
            subject_prefix = optarg;
            break;
        case ':':
            /* whinge, but ignore and continue */
            logentry(0, "option %c missing argument\n", optopt);
            break;
        case '?':
        default:
            /* ditto */
            logentry(0, "unknown argument %c\n", optopt);
            break;
        }
    }

    if (optind == argc) {
        logentry(1, "not enough arguments\n");
        usage();
    } else if (optind != (argc - 1)) {
        logentry(0, "extra arguments were supplied but will be ignored\n");
    }

    if (histfile == (char *) 0)
        histfile = ".autoreply/histfile";
}

/*
 * The keywords in mail headers are 7-bit ASCII, so use C locale
 * tolower() and such without regard for I18N.
 */

int
main(int argc, char *argv[])
{
    FILE *history_fp;
    FILE *message_fp;
    char *subject;
    const char *env_sender;
    const char *home;

    /*
     * qmail wants different exit codes to sendmail.
     *
     * postfix (and other sendmail replacements?) use sendmail
     * style exit codes so make them the default.
     *
     * EXT is chosen as it is one of the qmail variables mdforward
     * does not set and is not likely to set in the future.
     */
    if (getenv("EXT") != (char *) 0)
        exitcode = qmail_exit;
    else
        exitcode = sendmail_exit;

    count = DEFAULT_COUNT;
    interval = DEFAULT_INTERVAL;

    home = get_home();
    if (chdir(home) == -1) {
        logentry(1, "chdir to %s: %s\n", home, strerror(errno));
        EXIT(AU_FAIL_TEMP);
    }
    parse_options(argc, argv);
    if (logfp == (FILE *) 0)
        open_logfile(".autoreply/log");

    env_sender = getenv("SENDER");
    if (env_sender == (char *) 0)
        env_sender = ufline(stdin);	/* never freed */
    subject = check_headers(stdin);     /* sideffect: sets message_id */
    check_sender(env_sender);
    history_fp = check_history(env_sender);
    message_fp = build_response(env_sender, argv[optind], subject);
    send_response(env_sender, history_fp, message_fp);
    EXIT(AU_OK);        /* NOTREACHED */
}
