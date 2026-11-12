// Run against the actual earlyoom selector with a small synthetic /proc tree.
#include <assert.h>
#include <errno.h>
#include <regex.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>

#include "globals.h"
#include "kill.h"

static FILE *proc_file(int pid, const char *name)
{
    char path[4096];
    snprintf(path, sizeof(path), "%s/%d/%s", procdir_path, pid, name);
    FILE *file = fopen(path, "w");
    assert(file);
    return file;
}

static void mock_process(int pid, const char *name, long rss_kib, int score, int adj)
{
    char path[4096];
    snprintf(path, sizeof(path), "%s/%d", procdir_path, pid);
    assert(mkdir(path, 0700) == 0 || errno == EEXIST);
    FILE *file = proc_file(pid, "stat");
    fprintf(file, "%d (%s) S", pid, name);
    for (int field = 4; field <= 24; field++) {
        long value = 0;
        if (field == 4 || field == 20)
            value = 1; // ppid and num_threads
        if (field == 24)
            value = rss_kib * 1024 / sysconf(_SC_PAGESIZE);
        fprintf(file, " %ld", value);
    }
    fputs("\n", file);
    assert(fclose(file) == 0);
    file = proc_file(pid, "comm");
    fprintf(file, "%s\n", name);
    assert(fclose(file) == 0);
    file = proc_file(pid, "oom_score");
    fprintf(file, "%d\n", score);
    assert(fclose(file) == 0);
    file = proc_file(pid, "oom_score_adj");
    fprintf(file, "%d\n", adj);
    assert(fclose(file) == 0);
}

int main(int argc, char **argv)
{
    assert(argc == 4);
    procdir_path = argv[1];
    regex_t prefer, avoid;
    assert(regcomp(&prefer, argv[2], REG_EXTENDED | REG_NOSUB) == 0);
    assert(regcomp(&avoid, argv[3], REG_EXTENDED | REG_NOSUB) == 0);
    poll_loop_args_t args = {.sort_by_rss = true, .prefer_regex = &prefer, .avoid_regex = &avoid};
    const procinfo_t empty = {.pid = -9999, .oom_score = -9999, .VmRSSkiB = -9999};

    // A tiny, highly scored helper must lose to the actual large model worker.
    mock_process(100, "python3.12", 23 * 1024 * 1024, 680, 0);
    mock_process(101, "python", 24 * 1024, 1100, 200);
    procinfo_t model = {.pid = 100};
    assert(is_larger(&args, &empty, &model));
    procinfo_t helper = {.pid = 101};
    assert(!is_larger(&args, &model, &helper));
    assert(model.VmRSSkiB > 23 * 1024 * 1024); // Versioned Python preference applies.

    // Negative adjusted RSS must remain smaller in either traversal order.
    const char *protected[] = {
        ".Hyprland-wrapp", ".quickshell-wra", ".lianli-daemon-",
        "hypridle", "pipewire", "pipewire-pulse", "wireplumber", "systemd-coredum",
        "ChatGPT", "ChatGPT Helper"
    };
    for (unsigned i = 0; i < sizeof(protected) / sizeof(protected[0]); i++) {
        assert(regexec(&avoid, protected[i], 0, NULL, 0) == 0);
        mock_process(102, protected[i], 64 * 1024, 1200, 500);
        procinfo_t critical = {.pid = 102};
        assert(!is_larger(&args, &model, &critical));
        assert(critical.VmRSSkiB < 0);
        critical = (procinfo_t){.pid = 102};
        assert(is_larger(&args, &empty, &critical));
        procinfo_t candidate = {.pid = 100};
        assert(is_larger(&args, &critical, &candidate));
    }

    // Soft avoidance must not make a leaking session process immune.
    mock_process(103, ".quickshell-wra", 32 * 1024 * 1024, 800, 200);
    procinfo_t leak = {.pid = 103};
    assert(is_larger(&args, &model, &leak));

    // Preserve kernel immunity and the genuine zero-RSS fallback.
    mock_process(104, "rustc", 40 * 1024 * 1024, 900, -1000);
    procinfo_t immune = {.pid = 104};
    assert(!is_larger(&args, &model, &immune));
    mock_process(105, "zombie-main", 0, 1000, 0);
    procinfo_t zombie = {.pid = 105};
    assert(is_larger(&args, &model, &zombie));

    regfree(&prefer);
    regfree(&avoid);
    puts("earlyoom: RSS ranking, avoidance, versioned Python and immunity checks passed");
    return 0;
}
