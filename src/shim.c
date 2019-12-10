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
#include <regex.h>

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

int shim_exec(char *command) {
	char *executable;

	/* Break up command into array of arguments */
}

bool has_file_ext(char *filestr, char *ext) {
	size_t sz;
	int reti;
	regex_t regex;
	char *regex_str;

	sz = strlen(ext) + 3;
	regex_str = (char *) malloc(sz);
	strncat(regex_str, "\\.", sz);
	strncat(regex_str, ext, sz);
	strncat(regex_str, "$", sz);

	reti = regcomp(&regex, regex_str, 0);
	if (reti) exit_print(1, "failed to compile regex!\n");

	reti = regexec(&regex, filestr, 0, NULL, 0);
	return reti ? false : true;
}

char *remove_file_ext(char *filestr, char *ext) {
	size_t sz;
	char *ret_str;

	if (has_file_ext(filestr, ext)) {
		printf("%s\n", filestr);
		sz = strlen(filestr) - strlen(ext) - 1;
		ret_str = (char *) malloc(sz);
		for (int i = 0; i < sz; i++) {
			ret_str[i] = filestr[i];
		}

		printf("remove_file_ext: %s\n", ret_str);
	}

	return ret_str;
}

char *ext_compiled(char *filestr) {
	size_t sz;

	printf("compile_path = \n");

	return "";
}

char *ext_c(char *filestr, char *filename) {
	size_t sz;
	char *command, **exec_array;

	sz = strlen(DEFAULT_CC) + 1 + strlen(SCRIPT_DIR) + 1 + strlen(filestr) + 4 + strlen(filename) + 1 + strlen(COMPILED_EXTENSION) + 1;
	command = (char *) malloc(sz);
	snprintf(command, sz, "%s %s/%s -o %s.%s", DEFAULT_CC, SCRIPT_DIR, filestr, filename, COMPILED_EXTENSION);

	printf("command = %s\n", command);
	shim_exec(command);

	return "";
}

char *ext_py(char *filestr) {
	size_t sz;
	char *exec_path;

	sz = strlen(PYTHON_BIN) + strlen(" ") + strlen(SCRIPT_DIR) + strlen("/") + strlen(filestr) + 1;
	exec_path = (char *) malloc(sz);
	snprintf(exec_path, sz, "%s %s/%s", PYTHON_BIN, SCRIPT_DIR, filestr);
	printf("exec_path = %s\n", exec_path);

	return "";
}

char *ext_sh(char *filestr) {
	size_t sz;
	char *exec_path, sh_bin;

	sh_bin = SH_BIN;

	sz = strlen(sh_bin) + strlen(" ") + strlen(SCRIPT_DIR) + strlen("/") + strlen(filestr) + 1;
	exec_path = (char *) malloc(sz);
	snprintf(exec_path, sz, "%s %s/%s", sh_bin, SCRIPT_DIR, filestr);
	printf("exec_path = %s\n", exec_path);

	return "";
}

char *handle_file(char *arg)
{
	int arg_len, entry_len;
	bool found = false;
	DIR *directory;
	struct dirent *entry;
	char *exec_path, *file_name; // 0: name, 1: extension, 2: name and extension

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

		printf("entry->d_name: %s\n", entry->d_name);

		/* check if this is the file! */
		if ((file_name = remove_file_ext(entry->d_name, COMPILED_EXTENSION)) != NULL) {
			found = true;
			exec_path = ext_compiled(entry->d_name);
			break;
		} else if ((file_name = remove_file_ext(entry->d_name, "c")) != NULL) {
			found = true;
			exec_path = ext_c(entry->d_name, file_name);
			printf("exec_path: %s\n", exec_path);
			break;
		} else if ((file_name = remove_file_ext(entry->d_name, "py")) != NULL) {
			found = true;
			exec_path = ext_py(entry->d_name);
			printf("exec_path: %s\n", exec_path);
			break;
		} else if ((file_name = remove_file_ext(entry->d_name, "sh")) != NULL) {
			found = true;
			exec_path = ext_sh(entry->d_name);
			printf("exec_path: %s\n", exec_path);
			break;
		}
	}

	/* script not found, exiting */
	if (!found) exit_print(1, "script \'%s\' not found!\n", arg);

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

	if (argc == 1) exit_print(1, "no arguments supplied!\n");

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
