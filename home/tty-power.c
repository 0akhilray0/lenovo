#define _DEFAULT_SOURCE
#include <ncurses.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <dirent.h>

typedef struct {
    double watts;
    double cpu_watts;
    double voltage;
    double current;
    double wh_now;
    double wh_full;
    double wh_design;
    double health;
    double temp;
    int cap;
    int freq;
    int max_freq;
    char status[32];
    char gov[32];
    char time_rem[32];
    char cycles[16];
} PowerStats;

static char bat_path[128] = "/sys/class/power_supply/BAT0";
static long long last_rapl = -1;
static struct timespec last_time;

static long long read_ll(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) return -1;
    long long val = -1;
    if (fscanf(f, "%lld", &val) != 1) val = -1;
    fclose(f);
    return val;
}

static void read_str(const char *path, char *buf, size_t len) {
    FILE *f = fopen(path, "r");
    if (!f) { strncpy(buf, "Unknown", len); return; }
    if (fgets(buf, len, f)) {
        buf[strcspn(buf, "\r\n")] = 0;
    } else {
        strncpy(buf, "Unknown", len);
    }
    fclose(f);
}

static void init_paths(void) {
    DIR *d = opendir("/sys/class/power_supply");
    if (!d) return;
    struct dirent *de;
    while ((de = readdir(d)) != NULL) {
        if (strncmp(de->d_name, "BAT", 3) == 0) {
            snprintf(bat_path, sizeof(bat_path), "/sys/class/power_supply/%s", de->d_name);
            break;
        }
    }
    closedir(d);
}

static void poll_stats(PowerStats *s) {
    char p[256];
    snprintf(p, sizeof(p), "%s/status", bat_path);
    read_str(p, s->status, sizeof(s->status));

    snprintf(p, sizeof(p), "%s/capacity", bat_path);
    long long cap = read_ll(p);
    s->cap = (cap >= 0) ? (int)cap : 0;

    snprintf(p, sizeof(p), "%s/cycle_count", bat_path);
    read_str(p, s->cycles, sizeof(s->cycles));

    snprintf(p, sizeof(p), "%s/voltage_now", bat_path);
    long long v_raw = read_ll(p);
    s->voltage = (v_raw > 0) ? v_raw / 1e6 : 0.0;

    snprintf(p, sizeof(p), "%s/power_now", bat_path);
    long long p_raw = read_ll(p);
    if (p_raw >= 0) {
        s->watts = p_raw / 1e6;
        s->current = (s->voltage > 0) ? (s->watts / s->voltage) : 0.0;
    } else {
        snprintf(p, sizeof(p), "%s/current_now", bat_path);
        long long c_raw = read_ll(p);
        s->current = (c_raw > 0) ? c_raw / 1e6 : 0.0;
        s->watts = s->current * s->voltage;
    }

    long long rapl = read_ll("/sys/class/powercap/intel-rapl:0/energy_uj");
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    s->cpu_watts = -1.0;
    if (rapl >= 0) {
        if (last_rapl >= 0) {
            double dt = (now.tv_sec - last_time.tv_sec) + (now.tv_nsec - last_time.tv_nsec) / 1e9;
            if (dt > 0) {
                long long diff = rapl - last_rapl;
                if (diff < 0) diff += read_ll("/sys/class/powercap/intel-rapl:0/max_energy_range_uj");
                s->cpu_watts = (diff / 1e6) / dt;
            }
        }
        last_rapl = rapl;
        last_time = now;
    }
    if (s->watts == 0.0 && s->cpu_watts > 0) s->watts = s->cpu_watts;

    snprintf(p, sizeof(p), "%s/energy_now", bat_path);
    long long en = read_ll(p);
    snprintf(p, sizeof(p), "%s/energy_full", bat_path);
    long long ef = read_ll(p);
    snprintf(p, sizeof(p), "%s/energy_full_design", bat_path);
    long long ed = read_ll(p);

    if (en >= 0 && ef > 0) {
        s->wh_now = en / 1e6;
        s->wh_full = ef / 1e6;
        s->wh_design = (ed > 0) ? ed / 1e6 : s->wh_full;
        s->health = (s->wh_design > 0) ? (s->wh_full / s->wh_design) * 100.0 : 100.0;
    } else {
        snprintf(p, sizeof(p), "%s/charge_now", bat_path);
        long long cn = read_ll(p);
        snprintf(p, sizeof(p), "%s/charge_full", bat_path);
        long long cf = read_ll(p);
        snprintf(p, sizeof(p), "%s/charge_full_design", bat_path);
        long long cd = read_ll(p);
        double v_nom = s->voltage > 0 ? s->voltage : 11.1;
        s->wh_now = (cn > 0) ? (cn / 1e6) * v_nom : 0.0;
        s->wh_full = (cf > 0) ? (cf / 1e6) * v_nom : 0.0;
        s->wh_design = (cd > 0) ? (cd / 1e6) * v_nom : s->wh_full;
        s->health = (cd > 0 && cf > 0) ? ((double)cf / cd) * 100.0 : 100.0;
    }

    strncpy(s->time_rem, "Calculating...", sizeof(s->time_rem));
    if (s->watts > 0.2 && s->wh_now > 0) {
        double hrs = 0;
        if (strcmp(s->status, "Discharging") == 0) hrs = s->wh_now / s->watts;
        else if (strcmp(s->status, "Charging") == 0 && s->wh_full > s->wh_now)
            hrs = (s->wh_full - s->wh_now) / s->watts;
        if (hrs > 0 && hrs < 99) {
            int h = (int)hrs;
            int m = (int)((hrs - h) * 60);
            snprintf(s->time_rem, sizeof(s->time_rem), "%02d Hours %02d Minutes", h, m);
        }
    } else if (strcmp(s->status, "Full") == 0) {
        strncpy(s->time_rem, "Fully Charged", sizeof(s->time_rem));
    }

    long long f_khz = read_ll("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq");
    s->freq = (f_khz > 0) ? (int)(f_khz / 1000) : 0;
    long long mf_khz = read_ll("/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq");
    s->max_freq = (mf_khz > 0) ? (int)(mf_khz / 1000) : 3000;
    read_str("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor", s->gov, sizeof(s->gov));

    s->temp = 0.0;
    for (int i = 0; i < 6; i++) {
        snprintf(p, sizeof(p), "/sys/class/thermal/thermal_zone%d/temp", i);
        long long t = read_ll(p);
        if (t > 10000) { s->temp = t / 1000.0; break; }
    }
}

static void draw_double_hline(int y, int x, int w, const char *l, const char *r, int col) {
    attron(COLOR_PAIR(col));
    mvaddstr(y, x, l);
    for (int i = 1; i < w - 1; i++) mvaddstr(y, x + i, "═");
    mvaddstr(y, x + w - 1, r);
    attroff(COLOR_PAIR(col));
}

static void draw_grid_divider(int y, int x, int w, int mid_x, int col) {
    draw_double_hline(y, x, w, "╠", "╣", col);
    attron(COLOR_PAIR(col));
    mvaddstr(y, mid_x, "╬");
    attroff(COLOR_PAIR(col));
}

static void draw_full_bar(int y, int x, int width, double ratio, int active_col, int bg_col) {
    if (width < 4) return;
    if (ratio < 0.0) ratio = 0.0;
    if (ratio > 1.0) ratio = 1.0;
    int filled = (int)(ratio * width);

    attron(COLOR_PAIR(active_col) | A_BOLD);
    for (int i = 0; i < filled; i++) mvaddstr(y, x + i, "█");
    attroff(COLOR_PAIR(active_col) | A_BOLD);

    attron(COLOR_PAIR(bg_col));
    for (int i = filled; i < width; i++) mvaddstr(y, x + i, "─");
    attroff(COLOR_PAIR(bg_col));
}

static void draw_kv_cell(int y, int x, int cell_w, const char *label, const char *val, int val_col, int border_col) {
    int llen = (int)strlen(label);
    int vlen = (int)strlen(val);
    int lx = x + 3;
    int vx = x + cell_w - vlen - 4;
    if (vx < lx + llen + 2) vx = lx + llen + 2;

    attron(COLOR_PAIR(8) | A_BOLD);
    mvprintw(y, lx, "%s", label);
    attroff(COLOR_PAIR(8) | A_BOLD);

    // Subtle leader dots so wide full-screen columns never look empty in the middle
    attron(COLOR_PAIR(border_col));
    for (int cx = lx + llen + 2; cx < vx - 2; cx += 2) {
        mvaddstr(y, cx, "·");
    }
    attroff(COLOR_PAIR(border_col));

    attron(COLOR_PAIR(val_col) | A_BOLD);
    mvprintw(y, vx, "%s", val);
    attroff(COLOR_PAIR(val_col) | A_BOLD);
}

int main(void) {
    setlocale(LC_ALL, "");
    init_paths();
    initscr();
    noecho();
    curs_set(0);
    timeout(1000);
    start_color();
    use_default_colors();

    // 1:Red, 2:Green, 3:Yellow, 4:Blue, 5:Magenta, 6:Cyan, 7:White, 8:Terminal Default Foreground
    for (int i = 1; i <= 7; i++) init_pair(i, i, -1);
    init_pair(8, -1, -1);

    PowerStats s;
    double min_w = 999.0, max_w = 0.0, sum_w = 0.0;
    int samples = 0;
    int theme = 8; // Default: Elegant native terminal foreground color

    while (1) {
        poll_stats(&s);
        if (s.watts > 0.05) {
            if (s.watts < min_w) min_w = s.watts;
            if (s.watts > max_w) max_w = s.watts;
            sum_w += s.watts;
            samples++;
        }

        erase();
        int h, w;
        getmaxyx(stdscr, h, w);

        // Full-Screen Edge-to-Edge Dimensions
        int sy = 0, sx = 0;
        int bh = (h >= 22) ? h : 22;
        int bw = (w >= 76) ? w : 76;
        int mid_x = sx + (bw / 2);

        int load_c = (strcmp(s.status, "Charging") == 0) ? 6 : (s.watts < 10.0 ? 2 : (s.watts < 18.0 ? 3 : 1));
        int bat_c  = (s.cap > 40) ? 2 : (s.cap > 20 ? 3 : 1);
        int temp_c = (s.temp < 55.0) ? 6 : (s.temp < 75.0 ? 3 : 1);

        // Outer Double-Line Frame across 100% of the terminal window
        draw_double_hline(sy, sx, bw, "╔", "╗", theme);
        attron(COLOR_PAIR(theme));
        for (int r = 1; r < bh - 1; r++) {
            mvaddstr(sy + r, sx, "║");
            mvaddstr(sy + r, sx + bw - 1, "║");
        }
        attroff(COLOR_PAIR(theme));
        draw_double_hline(sy + bh - 1, sx, bw, "╚", "╝", theme);

        // Proportional Vertical Layout: dynamically scales to fill 100% of terminal height with zero void
        int footer_div_y = bh - 3;
        int avail_h = footer_div_y - 2; // Rows between header divider (y=2) and footer divider

        int hero_h = (avail_h >= 28) ? 4 : 3;
        int bars_y = 2 + hero_h;
        int bars_h = (avail_h >= 32) ? 6 : 4;
        int subhdr_y = bars_y + bars_h;
        int grid_top = subhdr_y + 2;
        int grid_bot = footer_div_y;
        int grid_h = grid_bot - grid_top;

        // Top Header Bar (Row 1)
        attron(COLOR_PAIR(6) | A_BOLD);
        mvprintw(sy + 1, sx + 3, "SYSTEM POWER & BATTERY TELEMETRY MONITOR");
        attroff(COLOR_PAIR(6) | A_BOLD);

        char st_str[48];
        snprintf(st_str, sizeof(st_str), "STATUS: %s", s.status);
        attron(COLOR_PAIR(load_c) | A_BOLD);
        mvprintw(sy + 1, sx + bw - (int)strlen(st_str) - 3, "%s", st_str);
        attroff(COLOR_PAIR(load_c) | A_BOLD);

        // Section 1: Twin Hero Summary Cells
        draw_double_hline(sy + 2, sx, bw, "╠", "╣", theme);
        attron(COLOR_PAIR(theme));
        mvaddstr(sy + 2, mid_x, "╦");
        for (int r = 3; r < bars_y; r++) mvaddstr(sy + r, mid_x, "║");
        attroff(COLOR_PAIR(theme));

        int hero_ty = sy + 2 + (hero_h - 2) / 2;
        attron(COLOR_PAIR(8) | A_BOLD);
        mvprintw(hero_ty, sx + 3, "LIVE POWER CONSUMPTION");
        mvprintw(hero_ty, mid_x + 3, "CURRENT BATTERY CAPACITY");
        attroff(COLOR_PAIR(8) | A_BOLD);

        attron(COLOR_PAIR(load_c) | A_BOLD);
        mvprintw(hero_ty + 1, sx + 3, "%.2f Watts  (%.2f Volts / %.2f Amperes)", s.watts, s.voltage, s.current);
        attroff(COLOR_PAIR(load_c) | A_BOLD);

        attron(COLOR_PAIR(bat_c) | A_BOLD);
        mvprintw(hero_ty + 1, mid_x + 3, "%d%% Charged  (%s)", s.cap, s.time_rem);
        attroff(COLOR_PAIR(bat_c) | A_BOLD);

        // Section 2: Full-Width Progress Meter Bars
        draw_double_hline(bars_y, sx, bw, "╠", "╣", theme);
        attron(COLOR_PAIR(theme));
        mvaddstr(bars_y, mid_x, "╩");
        attroff(COLOR_PAIR(theme));

        int bar_x = sx + 28;
        int bar_w = bw - 45;
        int b1_y = bars_y + 1;
        int b2_y = (bars_h >= 6) ? bars_y + 3 : bars_y + 2;
        int b3_y = (bars_h >= 6) ? bars_y + 5 : bars_y + 3;

        attron(COLOR_PAIR(8) | A_BOLD);
        mvprintw(b1_y, sx + 3, "Power Consumption Bar  :");
        mvprintw(b2_y, sx + 3, "Battery Charge Level   :");
        mvprintw(b3_y, sx + 3, "Processor Clock Speed  :");
        attroff(COLOR_PAIR(8) | A_BOLD);

        draw_full_bar(b1_y, bar_x, bar_w, s.watts / 35.0, load_c, theme);
        attron(COLOR_PAIR(load_c) | A_BOLD);
        mvprintw(b1_y, bar_x + bar_w + 2, "%6.2f Watts", s.watts);
        attroff(COLOR_PAIR(load_c) | A_BOLD);

        draw_full_bar(b2_y, bar_x, bar_w, s.cap / 100.0, bat_c, theme);
        attron(COLOR_PAIR(bat_c) | A_BOLD);
        mvprintw(b2_y, bar_x + bar_w + 2, "%6d Percent", s.cap);
        attroff(COLOR_PAIR(bat_c) | A_BOLD);

        draw_full_bar(b3_y, bar_x, bar_w, (double)s.freq / s.max_freq, 6, theme);
        attron(COLOR_PAIR(6) | A_BOLD);
        mvprintw(b3_y, bar_x + bar_w + 2, "%6d MHz", s.freq);
        attroff(COLOR_PAIR(6) | A_BOLD);

        // Section 3: Telemetry Subheaders
        draw_double_hline(subhdr_y, sx, bw, "╠", "╣", theme);
        attron(COLOR_PAIR(theme));
        mvaddstr(subhdr_y, mid_x, "╦");
        for (int r = subhdr_y + 1; r < footer_div_y; r++) mvaddstr(r, mid_x, "║");
        attroff(COLOR_PAIR(theme));

        attron(COLOR_PAIR(6) | A_BOLD);
        mvprintw(subhdr_y + 1, sx + 3, "ELECTRICAL & ENERGY TELEMETRY");
        mvprintw(subhdr_y + 1, mid_x + 3, "PROCESSOR & HARDWARE TELEMETRY");
        attroff(COLOR_PAIR(6) | A_BOLD);

        // Section 4: 5 Boxed Rows Distributed Evenly Across Remaining Window Height
        double avg_w = samples > 0 ? sum_w / samples : s.watts;
        double disp_min = min_w < 900.0 ? min_w : s.watts;
        int left_w = mid_x - sx;
        int right_w = (sx + bw - 1) - mid_x;

        const char *l_labels[5] = {
            "Minimum Power Draw",
            "Average Power Draw",
            "Maximum Peak Power",
            "Stored Battery Energy",
            "Full / Design Capacity"
        };
        const char *r_labels[5] = {
            "Processor Frequency",
            "Power Scaling Governor",
            "Processor Temperature",
            "Battery Health Status",
            "Voltage & Charge Cycles"
        };

        char l_vals[5][64], r_vals[5][64];
        snprintf(l_vals[0], 64, "%.2f Watts", disp_min);
        snprintf(l_vals[1], 64, "%.2f Watts", avg_w);
        snprintf(l_vals[2], 64, "%.2f Watts", max_w);
        snprintf(l_vals[3], 64, "%.2f Watt-Hours", s.wh_now);
        snprintf(l_vals[4], 64, "%.2f / %.2f Watt-Hours", s.wh_full, s.wh_design);

        snprintf(r_vals[0], 64, "%d MHz (Max %d MHz)", s.freq, s.max_freq);
        snprintf(r_vals[1], 64, "%s", s.gov);
        snprintf(r_vals[2], 64, "%.1f Degrees Celsius", s.temp);
        snprintf(r_vals[3], 64, "%.1f%% Capacity Retained", s.health);
        snprintf(r_vals[4], 64, "%.2f Volts  |  %s Cycles", s.voltage, s.cycles);

        int l_cols[5] = {2, 6, 3, bat_c, 4};
        int r_cols[5] = {6, 5, temp_c, (s.health > 60 ? 2 : 3), 4};

        for (int i = 0; i < 5; i++) {
            int row_top = grid_top + (i * grid_h) / 5;
            int row_bot = grid_top + ((i + 1) * grid_h) / 5;
            int text_y  = row_top + (row_bot - row_top) / 2;

            draw_grid_divider(row_top, sx, bw, mid_x, theme);
            draw_kv_cell(text_y, sx + 1, left_w, l_labels[i], l_vals[i], l_cols[i], theme);
            draw_kv_cell(text_y, mid_x + 1, right_w, r_labels[i], r_vals[i], r_cols[i], theme);
        }

        // Bottom Controls Bar
        draw_double_hline(footer_div_y, sx, bw, "╠", "╣", theme);
        attron(COLOR_PAIR(theme));
        mvaddstr(footer_div_y, mid_x, "╩");
        attroff(COLOR_PAIR(theme));

        attron(COLOR_PAIR(8));
        mvprintw(footer_div_y + 1, sx + 3, "CONTROLS:   [C] Cycle Border Color     [R] Reset Statistics     [Q] Quit Monitor");
        attroff(COLOR_PAIR(8));

        refresh();

        int ch = getch();
        if (ch == 'q' || ch == 'Q') break;
        else if (ch == 'c' || ch == 'C') theme = (theme % 8) + 1;
        else if (ch == 'r' || ch == 'R') { min_w = 999.0; max_w = 0.0; sum_w = 0.0; samples = 0; }
    }

    endwin();
    return 0;
}
