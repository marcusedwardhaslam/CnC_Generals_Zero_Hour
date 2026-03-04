#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <limits.h>

#ifdef _WIN32
#include <direct.h>
#include <io.h>
#define ACCESS _access
#define GETCWD _getcwd
#define CHDIR _chdir
#define MKDIR(path) _mkdir(path)
#define F_OK 0
#else
#include <libgen.h>
#include <unistd.h>
#include <sys/stat.h>
#define ACCESS access
#define GETCWD getcwd
#define CHDIR chdir
#define MKDIR(path) mkdir(path, 0755)
#endif

#define PATH_BUFFER_LENGTH (FILENAME_MAX + 1)
#define OPTIONS_MAX_LENGTH 4
#define LINE_MAX_LENGTH    1024
#define TOKEN_MAX_LENGTH   256

typedef struct {
    char *input_path;
    char *output_path;
    char options[OPTIONS_MAX_LENGTH];
} cmd_args;

typedef struct macro macro;
typedef struct macro {
    char *name;
    size_t name_len;
    char *value;
    size_t value_len;
    macro *next;
} macro;

typedef enum {
    shader_none = 0,
    shader_vertex = 1,
    shader_pixel = 2
} shader_type;

typedef struct {
    const char *path;
    FILE *fp;
    char line[LINE_MAX_LENGTH];
    size_t line_len;
    size_t line_num;
} file_data;

static char *path_basename_mut(char *path) {
    char *p1 = strrchr(path, '/');
    char *p2 = strrchr(path, '\\');
    char *p = p1 > p2 ? p1 : p2;
    return p ? p + 1 : path;
}

static char *path_dirname_mut(char *path) {
    char *p1 = strrchr(path, '/');
    char *p2 = strrchr(path, '\\');
    char *p = p1 > p2 ? p1 : p2;
    if (!p) {
        strcpy(path, ".");
        return path;
    }
    *p = '\0';
    return path;
}

static int ensure_parent_dir(const char *path) {
    char tmp[PATH_BUFFER_LENGTH];
    size_t len = strlen(path);
    if (len >= sizeof(tmp)) {
        return 0;
    }
    strcpy(tmp, path);
    path_dirname_mut(tmp);
    if (strcmp(tmp, ".") == 0 || strcmp(tmp, "") == 0) {
        return 1;
    }
    if (ACCESS(tmp, F_OK) == 0) {
        return 1;
    }
    return MKDIR(tmp) == 0;
}

int arguments_read(cmd_args *const args, const int argc, char **argv) {
    int i;
    args->input_path = NULL;
    args->output_path = NULL;
    args->options[0] = '\0';

    for (i = 1; i < argc; ++i) {
        char *cur_arg = argv[i];
        if (cur_arg[0] == '-' && strchr(&cur_arg[1], 'h')) {
            strcpy(args->options, "-h ");
        } else if (args->input_path == NULL) {
            if (ACCESS(cur_arg, F_OK) == 0) {
                args->input_path = cur_arg;
            } else {
                printf("Input file at \"%s\" does not exist!\n", cur_arg);
                return 0;
            }
        } else if (args->output_path == NULL) {
            args->output_path = cur_arg;
        }
    }
    return args->input_path != NULL;
}

shader_type get_shader_type(const char *const input_path) {
    shader_type type = shader_none;
    FILE *const input_file = fopen(input_path, "r");
    if (input_file == NULL) {
        printf("Could not open input file at \"%s\".\n", input_path);
    } else {
        char line[LINE_MAX_LENGTH];
        while (fgets(line, LINE_MAX_LENGTH, input_file) != NULL) {
            if (strncmp(line, "vs", 2) == 0) {
                type = shader_vertex;
                break;
            } else if (strncmp(line, "ps", 2) == 0) {
                type = shader_pixel;
                break;
            }
        }
        fclose(input_file);
    }
    return type;
}

int get_compile_path(char *compile_path, const cmd_args *const args, const shader_type type) {
    char *start_pos;
    char *ext_pos;
    size_t compile_path_len;

    strcpy(compile_path, args->input_path);
    start_pos = path_basename_mut(compile_path);
    compile_path_len = strlen(start_pos);
    memmove(compile_path, start_pos, compile_path_len + 1);

    ext_pos = strrchr(compile_path, '.');
    if (ext_pos == NULL) {
        ext_pos = &compile_path[compile_path_len];
    } else {
        compile_path_len = (size_t)(ext_pos - compile_path);
    }

    if (args->options[0] == '\0') {
        if (compile_path_len + 4 > FILENAME_MAX) {
            puts("Unable to create temporary file: input path too long.");
            return 1;
        }
        switch (type) {
            case shader_none:
                puts("Unable to create temporary file: invalid shader type.");
                return 1;
            case shader_vertex:
                strcpy(&compile_path[compile_path_len], ".vso");
                break;
            case shader_pixel:
                strcpy(&compile_path[compile_path_len], ".pso");
                break;
        }
    } else {
        if (compile_path_len + 2 > FILENAME_MAX) {
            puts("Unable to create temporary file: input path too long.");
            return 1;
        }
        strcpy(&compile_path[compile_path_len], ".h");
    }
    return 0;
}

void print_file_error(const file_data *const fd, const char *const error) {
    printf("%s(%u)> %s\n", fd->path, (unsigned)fd->line_num, error);
}

int macro_process(const file_data *const fd, macro **list);

int macro_include_header(const file_data *const fd, macro **list) {
    char old_dir[PATH_BUFFER_LENGTH];
    char new_dir[PATH_BUFFER_LENGTH];
    char include_path[TOKEN_MAX_LENGTH];
    file_data include;
    int success = 1;

    if (GETCWD(old_dir, sizeof(old_dir)) == NULL) {
        perror("Error calling getcwd()");
    }

    strcpy(new_dir, fd->path);
    if (CHDIR(path_dirname_mut(new_dir)) == -1) {
        printf("Failed to change to subdirectory \"%s\".\n", new_dir);
    }

    sscanf(fd->line, "#include \"%[^\"]", include_path);
    include.path = include_path;
    include.fp = fopen(include.path, "r");
    if (include.fp == NULL) {
        printf("Could not include header file at \"%s\".\n", include.path);
        success = 0;
    } else {
        include.line_num = 0;
        while (fgets(include.line, LINE_MAX_LENGTH, include.fp) != NULL) {
            include.line_len = strlen(include.line);
            ++include.line_num;
            if (include.line[0] == '#') {
                if (!macro_process(&include, list)) {
                    print_file_error(&include, "Macro registration failure.");
                }
            }
        }
        fclose(include.fp);
    }

    if (CHDIR(old_dir) == -1) {
        printf("Failed to change to old directory \"%s\".\n", old_dir);
    }
    return success;
}

void macro_insertion_sort(macro **list, macro *const node) {
    macro *cur_macro = *list;
    while (cur_macro != NULL && node->name_len < cur_macro->name_len) {
        list = &cur_macro->next;
        cur_macro = *list;
    }
    node->next = cur_macro;
    *list = node;
}

int macro_register(const file_data *const fd, macro **list) {
    char name[TOKEN_MAX_LENGTH];
    size_t name_len;
    char value[TOKEN_MAX_LENGTH];
    size_t value_len;
    macro *new_macro;

    if (sscanf(fd->line, "#define %255s %255s", name, value) < 2) {
        print_file_error(fd, "Invalid #define format.");
        return 0;
    }

    name_len = strlen(name);
    value_len = strlen(value);
    new_macro = (macro *)malloc(sizeof(*new_macro) + name_len + value_len + 2);
    if (new_macro == NULL) {
        print_file_error(fd, "Memory allocation failure.");
        return 0;
    }

    new_macro->name = (char *)&new_macro[1];
    new_macro->name_len = name_len;
    new_macro->value = &new_macro->name[name_len + 1];
    new_macro->value_len = value_len;
    new_macro->next = NULL;

    strcpy(new_macro->name, name);
    strcpy(new_macro->value, value);
    macro_insertion_sort(list, new_macro);
    return 1;
}

int macro_process(const file_data *const fd, macro **list) {
    if (strncmp(&fd->line[1], "include", 7) == 0) {
        return macro_include_header(fd, list);
    } else if (strncmp(&fd->line[1], "define", 6) == 0) {
        return macro_register(fd, list);
    }
    return 1;
}

void macro_replace_line(file_data *const fd, const macro *const list) {
    const macro *cur_macro = list;
    while (cur_macro != NULL) {
        char *const macro_pos = strstr(fd->line, cur_macro->name);
        if (macro_pos == NULL) {
            cur_macro = cur_macro->next;
        } else {
            memmove(
                &macro_pos[cur_macro->value_len],
                &macro_pos[cur_macro->name_len],
                (size_t)(&fd->line[fd->line_len] - macro_pos)
            );
            strncpy(macro_pos, cur_macro->value, cur_macro->value_len);
            fd->line_len += cur_macro->value_len - cur_macro->name_len;
            cur_macro = list;
        }
    }
}

int macro_replace_file(const char *const input_path, const char *const output_path) {
    file_data input;
    input.path = input_path;
    input.fp = fopen(input.path, "r");
    if (input.fp == NULL) {
        printf("Could not open input file at \"%s\".\n", input.path);
        return 0;
    }

    FILE *const output_file = fopen(output_path, "w");
    if (output_file == NULL) {
        fclose(input.fp);
        printf("Could not open output file at \"%s\".\n", output_path);
        return 0;
    }

    macro *macro_list = NULL;
    input.line_num = 0;
    while (fgets(input.line, LINE_MAX_LENGTH, input.fp) != NULL) {
        input.line_len = strlen(input.line);
        ++input.line_num;
        macro_replace_line(&input, macro_list);
        if (input.line[0] == '#') {
            if (!macro_process(&input, &macro_list)) {
                print_file_error(&input, "Macro registration failure.");
            }
        } else {
            fwrite(input.line, sizeof(*input.line), input.line_len, output_file);
        }
    }

    while (macro_list != NULL) {
        macro *const macro_next = macro_list->next;
        free(macro_list);
        macro_list = macro_next;
    }

    fclose(output_file);
    fclose(input.fp);
    return 1;
}

int shader_compile(const char *const compile_path, const char *const options, const shader_type type) {
    char cmd[LINE_MAX_LENGTH];
    switch (type) {
        case shader_none:
            puts("Unable to compile shader: invalid shader type.");
            return 0;
        case shader_vertex:
            snprintf(cmd, sizeof(cmd), "vsa.exe %s\"%s\"", options, compile_path);
            break;
        case shader_pixel:
            snprintf(cmd, sizeof(cmd), "psa.exe %s\"%s\"", options, compile_path);
            break;
    }
    if (system(cmd) != 0) {
        puts("Shader compilation failed.");
        return 0;
    }
    return 1;
}

size_t output_generate_line(char *const line, const char *const input_path, const shader_type type) {
    char input_name[PATH_BUFFER_LENGTH];
    char *temp_pos;
    strcpy(input_name, input_path);
    temp_pos = strrchr(input_name, '.');
    if (temp_pos != NULL) {
        *temp_pos = '\0';
    }
    temp_pos = path_basename_mut(input_name);
    memmove(input_name, temp_pos, strlen(temp_pos) + 1);
    input_name[0] = (char)toupper((unsigned char)input_name[0]);

    if (type == shader_vertex) {
        sprintf(line, "DWORD dw%sVertexShader[] = {\r\n", input_name);
    } else {
        sprintf(line, "DWORD dw%sPixelShader[] = {\r\n", input_name);
    }
    return strlen(line);
}

size_t output_get_size(FILE *const output, const size_t first_line_len) {
    int ch;
    size_t output_size = first_line_len;
    while ((ch = fgetc(output)) != EOF && ch != '\n') {}
    while (fgetc(output) != EOF) {
        ++output_size;
    }
    rewind(output);
    return output_size;
}

int output_update(const char *const input_path, const char *const output_path, const shader_type type) {
    FILE *output_file = fopen(output_path, "rb");
    if (output_file == NULL) {
        printf("Could not open output file at \"%s\".\n", output_path);
        return 1;
    }

    char first_line[LINE_MAX_LENGTH];
    const size_t first_line_len = output_generate_line(first_line, input_path, type);
    const size_t output_size = output_get_size(output_file, first_line_len);
    char *const output_data = (char *)malloc(output_size);
    if (output_data == NULL) {
        fclose(output_file);
        puts("Failed to allocate memory for output file.");
        return 1;
    }

    memcpy(output_data, first_line, first_line_len);
    while (fgetc(output_file) != '\n') {}
    fread(&output_data[first_line_len], sizeof(*output_data), output_size - first_line_len, output_file);

    output_file = freopen(output_path, "wb", output_file);
    if (output_file == NULL) {
        free(output_data);
        puts("Could not change mode of output file.");
        return 1;
    }

    fwrite(output_data, sizeof(*output_data), output_size, output_file);
    fclose(output_file);
    free(output_data);
    return 0;
}

int main(int argc, char **argv) {
    cmd_args args;
    shader_type type;
    char compile_path[PATH_BUFFER_LENGTH];

    if (!arguments_read(&args, argc, argv)) {
        puts(
            "Invalid command line arguments.\n"
            "Usage: nvasm.exe -[OPTIONS] \"input_path\" \"output_path\"\n"
            "Options:\n"
            "  h\tCompile to a header file"
        );
        return 1;
    }

    if (args.output_path != NULL) {
        remove(args.output_path);
    }

    type = get_shader_type(args.input_path);
    if (type == shader_none) {
        puts("Invalid shader format specified.");
        return 1;
    }

    if (get_compile_path(compile_path, &args, type) != 0) {
        return 1;
    }

    if (!macro_replace_file(args.input_path, compile_path) || !shader_compile(compile_path, args.options, type)) {
        return 1;
    }

    if (args.output_path == NULL) {
        args.output_path = compile_path;
    } else {
        if (!ensure_parent_dir(args.output_path)) {
            puts("Warning: could not create output directory; attempting rename anyway.");
        }
        if (rename(compile_path, args.output_path) != 0) {
            puts("Failed to rename output file. Using default output file.");
            args.output_path = compile_path;
        }
    }

    if (args.options[0] != '\0') {
        return output_update(args.input_path, args.output_path, type);
    }
    return 0;
}
