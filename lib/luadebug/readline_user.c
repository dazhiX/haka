
#include <editline/readline.h>
#include <stdlib.h>

#include <haka/error.h>

#include <luadebug/user.h>


static bool readline_initialized = false;

static struct luadebug_user *current = NULL;

static int empty_generator(const char *text, int state)
{
	return 0;
}

static char **complete(const char *text, int start, int end)
{
	generator_callback *generator = current->completion(rl_line_buffer, start);
	if (generator) {
		return rl_completion_matches(text, generator);
	}
	else {
		return NULL;
	}
}

static void start(struct luadebug_user *data, const char *name)
{
	if (!readline_initialized) {
		rl_initialize();
		readline_initialized = true;
	}

	current = data;

	rl_basic_word_break_characters = " \t\n`@$><=;|&{(";
	rl_readline_name = (char *)name;
	rl_attempted_completion_function = complete;
	rl_completion_entry_function = empty_generator;
	using_history();
}

static char *my_readline(struct luadebug_user *data, const char *prompt)
{
	return readline(prompt);
}

static void addhistory(struct luadebug_user *data, const char *line)
{
	add_history(line);
}

static void stop(struct luadebug_user *data)
{
	current = NULL;
}

static void destroy(struct luadebug_user *data)
{
	free(data);
}

struct luadebug_user *luadebug_user_readline()
{
	struct luadebug_user *ret = malloc(sizeof(struct luadebug_user));
	if (!ret) {
		error(L"memory error");
		return NULL;
	}

	ret->start = start;
	ret->readline = my_readline;
	ret->addhistory = addhistory;
	ret->stop = stop;
	ret->destroy = destroy;

	return ret;
}
