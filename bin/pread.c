#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

int main(int argc, char **argv) {
  const char *path;
  off_t offset;
  size_t length;
  char *buf;
  ssize_t res;
  int fd;

  if (argc != 4) {
    fprintf(stderr, "Usage: %s <filename> <offset> <length>\n", argv[0]);
    return 1;
  }

  path = argv[1];
  offset = (off_t)atoll(argv[2]);
  length = (size_t)atoll(argv[3]);

  fd = open(path, O_RDONLY);
  if (fd < 0) {
    fprintf(stderr, "Unable to open(%s): %s\n", path, strerror(errno));
    return 1;
  }

  buf = malloc(length);
  if (!buf) {
    fprintf(stderr, "Unable to allocate buffer of size %lu: %s\n", length,
            strerror(errno));
    return 1;
  }

  res = pread(fd, buf, length, offset);
  if (res < 0) {
    fprintf(stderr, "Unable to read {offset:%llu, length:%lu}: %s\n", offset,
            length, strerror(errno));
    return 1;
  }

  write(STDOUT_FILENO, buf, (size_t)res);

  free(buf);
  close(fd);
  return 0;
}
