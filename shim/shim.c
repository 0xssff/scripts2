#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdbool.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <pwd.h>
#include <string.h>
#include <dirent.h>
#include <errno.h>

#define USER_SUBDIR			"/.user"
#define SCRIPT_SUBDIR			USER_SUBDIR "/scripts"
#define COMPILED_EXTENSION		"out"
#define FILE_EXT_MAX			5

#define DEFAULT_CC			"gcc"
#define SH_BIN				"sh"
#define PYTHON_BIN			"python"

static char *HOME_DIR;
static char *USER_DIR;
static char *SCRIPT_DIR;

void cleanup(void)
{
	free(HOME_DIR);
	free(USER_DIR);
	free(SCRIPT_DIR);
}

void exit_print(int code, const char *format, ...)
{
	va_list argp;

	/* pass string + format arguments to vfprintf */
	va_start(argp, format);
	vfprintf(stderr, format, argp);
	va_end(argp);

	cleanup();
	exit(code);
}

void set_dirs(void)
{
	size_t sz;
	uid_t uid;
	struct passwd *pwd;

	uid = getuid();

	if ((pwd = getpwuid(uid)) == NULL) {
		exit_print(1, "Unable to get user (%i) passwd structure!\n", uid);
	}

	sz = strlen(pwd->pw_dir) + 1;
	HOME_DIR = (char *) malloc(sz);
	snprintf(HOME_DIR, sz, "%s", pwd->pw_dir);

	sz = strlen(HOME_DIR) + strlen(USER_SUBDIR) + 1;
	USER_DIR = (char *) malloc(sz);
	snprintf(USER_DIR, sz, "%s%s", HOME_DIR, USER_SUBDIR);

	sz = strlen(HOME_DIR) + strlen(SCRIPT_SUBDIR) + 1;
	SCRIPT_DIR = (char *) malloc(sz);
	snprintf(SCRIPT_DIR, sz, "%s%s", HOME_DIR, SCRIPT_SUBDIR);
}

void check_dirs(void)
{
	struct stat *dir_stat = (struct stat *) malloc(sizeof(struct stat));

	if (stat(USER_DIR, dir_stat) != 0 || ! S_ISDIR(dir_stat->st_mode)) {
		free(dir_stat);
		exit_print(1, "Directory \'%s\' does not exist\n", USER_DIR);
	}

	if (stat(SCRIPT_DIR, dir_stat) != 0 || ! S_ISDIR(dir_stat->st_mode)) {
		free(dir_stat);
		exit_print(1, "Directory \'%s\' does not exist\n", SCRIPT_DIR);
	}
}

void append_string(char *dest, char *src, int num)
{
	size_t dest_sz, src_sz;
	int di, si;

	dest_sz = strlen(dest);
	src_sz = strlen(src);
	if (num >= src_sz) num = src_sz - 1;

	while (di < dest_sz && si < num) {
		if (dest[di] == 0) {
			dest[di] = src[si];
			si++;
		}

		di++;
	}
}

char **name_ext_split(char *string)
{
	size_t sz;
	char *name, *split, *delim = ".", *file_array[3];

	printf("name_ext_split()\n");

	/* setup name string */
	printf("setting initial string\n");
	sz = strlen(string);
	name = (char *) malloc(sz);
	split = (char *) malloc(FILE_EXT_MAX);
	memset(name, 0, sz);

	/* if file begins with '.', this'll be stripped so check and set */
	printf("if file begins with '.', this'll be stripped so check and set\n");
	if (strncmp(string, ".", 1) == 0)
		append_string(name, ".", 1);

	/* final split is the file extension */
	split = strtok(string, delim);
	while (split != NULL) {
		printf("split: %s\n", split);
		append_string(name, split, strlen(split));
		split = strtok(NULL, delim);
	}

	/* final split is the file extension */
	printf("making the file array\n");
	printf("name = %s\n", name);
	file_array[0] = name;
	printf("extension = %s\n", split);
	file_array[1] = split;
	printf("name + extension = %s\n", string);
	file_array[2] = string;

	/* cleanup */
	printf("cleaning up...\n");
	free(name);

	return file_array;
}



char *ext_c(char **file_array)
{
	size_t sz;
	char *compile_path, **exec_array;

	sz = strlen(DEFAULT_CC) + strlen(" ") + strlen(SCRIPT_DIR) + strlen("/") + strlen(file_array[3]) + strlen(" -o ") + strlen(file_array[1]) + strlen(".") + strlen(COMPILED_EXTENSION) + 1;
	compile_path = (char *) malloc(sz);
	snprintf(compile_path, sz, "%s %s/%s -o %s.%s", DEFAULT_CC, SCRIPT_DIR, file_array[3], file_array[1], COMPILED_EXTENSION);
	printf("compile_path = %s\n", compile_path);

	return "";
}

char *ext_py(char **file_array)
{
	size_t sz;
	char *exec_path;

	sz = strlen(PYTHON_BIN) + strlen(" ") + strlen(SCRIPT_DIR) + strlen("/") + strlen(file_array[3]) + 1;
	exec_path = (char *) malloc(sz);
	snprintf(exec_path, sz, "%s %s/%s", PYTHON_BIN, SCRIPT_DIR, file_array[3]);
	printf("exec_path = %s\n", exec_path);

	return "";
}

char *handle_file(char *arg)
{
	int arg_len, entry_len;
	bool found = false;
	DIR *directory;
	struct dirent *entry;
	char *exec_path, **file_array; // 0: name, 1: extension, 2: name and extension

	if ((directory = opendir(SCRIPT_DIR)) == NULL) {
		exit_print(1, "Unable to open scripts directory \'%s\'\n", SCRIPT_DIR);
	}

	/* calculate once to prevent repeated calls to strlen */
	arg_len = strlen(arg);

	while ((entry = readdir(directory)) != NULL) {
		/* calculate once */
		entry_len = strlen(entry->d_name);

		/* ignore '.' and '..' */
		if (strncmp(entry->d_name, ".", entry_len) == 0 || strncmp(entry->d_name, "..", strlen(entry->d_name)) == 0)
			continue;

		/* don't waste further execution time if entry name too short or
		 * beginning of entry string doesn't match search string
		 */
		if (entry_len < arg_len || strncmp(entry->d_name, arg, arg_len) != 0)
			continue;

		/* strip file extension */
		printf("stripping file extension...\n");
		file_array = name_ext_split(entry->d_name);
		printf("file_array --> 0:%s 1:%s 2:%s\n", file_array[0], file_array[1], file_array[2]);

		/* check if this is the file! */
		printf("checking if right file...\n");
		if (strncmp(file_array[0], arg, arg_len)) {
			printf("we found the right file!\n");
			found = true;
			break;
		}
	}

	if (!found) exit_print(1, "Script \'%s\' not found!\n", arg);

	/* deal with file extension */
	printf("dealing with extension...\n");
	if (strncmp(file_array[1], "c", 1) == 0) {
		exec_path = ext_c(file_array);
	} else if (strncmp(file_array[1], "py", 2) == 0) {
		exec_path = ext_py(file_array);
	} else {
		exit_print(1, "File extension \'%s\' not supported\n", file_array[1]);
	}

	/* return exec_path! */
	return exec_path;
}

int main(int argc, char **argv)
{
	int i;
	char *exec_path, *exec_array; // 0: cmd, 1-->: args

	/* setup HOME, USER and SCRIPT global variables */
	set_dirs();

	/* check USER AND SCRIPT directories exist */
	check_dirs();

	/* find file, handle file (compile / append program path / etc) and return executable path */
	exec_path = handle_file(argv[1]);
	exec_array = (char **) malloc(sizeof(char *) * (argc - 2));
	for (i = 0; i < argc - 2; i++) {
		exec_array[i] = argv[i + 2];
	}

	/* execute exec_path ! */
	i = execvp(exec_path, exec_array);

	if (i != 0) exit_print(i, "exited with error %i: %s\n", i, strerror(i));
	else {
		cleanup();
		exit(0);
	}
}
