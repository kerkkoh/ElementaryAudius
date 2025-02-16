/*
* Idk why I'm even including this license in here. I guess no warranty? YEAH! No warranty! THAT'S RIGHT. You heard me.
*
* The MIT License (MIT)
*
* Copyright (c) 2020 Kerkkoh
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Authored by: Kerkkoh <superihippo@gmail.com>
*/

public class Application : Gtk.Application {

    private static StreamPlayer player;
    private bool has_played = false;
    private bool show_notifications = true;
    private Gee.ArrayList<User?> m_results;

    public Application () {
        Object (
            application_id: "com.github.ElementaryAudius",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    private void show_notification (string title, string body, string icon = "applications-multimedia") {
        if (!show_notifications) return;

        var notification = new Notification (_(title));
        notification.set_body (_(body));
        notification.set_icon (new GLib.ThemedIcon (icon));
        send_notification ("com.github.kerkkoh.ElementaryAudius", notification);
    }

    private void play(ref Gtk.LinkButton link_button, ref Gtk.Label playing_label, ref Gtk.Image album_art, bool in_order, int delta = 0) {
        if (player.total_tracks() == 0) return;
        player.get_trending (in_order, delta);
        player.stop ();
        player.play ();
    }

    private void pause_or_play (ref Gtk.LinkButton link_button, ref Gtk.Label playing_label, ref Gtk.Image album_art, ref Gtk.Button pause_button, ref Gtk.Button play_button) {
        if (!has_played) {
            play(ref link_button, ref playing_label, ref album_art, true, 0);
            has_played = true;
        }
        if (player.is_playing ()) {
            pause_button.hide();
            play_button.show();
        } else {
            play_button.hide();
            pause_button.show();
        }
        player.pause ();
    }

    private string seconds_to_hms (int64 seconds) {
        string result = "";
        double h = GLib.Math.floor ((double) seconds / (60*60));
        if (h > 0) {
            seconds -= 60*60*((int64) h);
            result += h.to_string() + ":";
        }
        double m = GLib.Math.floor ((double) seconds / 60);
        result += m.to_string() + ":";
        if (m > 0) {
            seconds -= 60*((int64) m);
        }
        var secprefix = seconds < 10 ? "0" : "";
        result += secprefix + seconds.to_string();
        return result;
    }
    private void update_duration_bar (int64 current, int64 duration, ref Gtk.Label duration_label, ref Gtk.Scale slider, ref Gtk.Label duration_full) {
        slider.adjustment.value = ((double) current / (double) duration)*1000;
        duration_label.set_label(_(seconds_to_hms(current)));
        duration_full.set_label(_(seconds_to_hms(duration)));
    }

    protected override void activate () {
        var main_window = new Gtk.ApplicationWindow (this);
        main_window.set_icon_name("applications-multimedia");
        main_window.default_height = 300;
        main_window.default_width = 280;
        main_window.title = "ElementaryAudius";
        var search_label = new Gtk.Label (_("Search for an artist:"));
        var search_entry = new Gtk.SearchEntry ();
        var search_results = new Gtk.ListBox ();
        var title_label = new Gtk.Label (_("Now playing from Trending:"));
        var playing_label = new Gtk.Label (_("Loading Audius..."));
        var album_art = new Gtk.Image ();
        var duration_label = new Gtk.Label (_(""));
        var duration_slider = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 1000, 1);
        var duration_full = new Gtk.Label (_(""));
        var random_button = new Gtk.Button.with_label (_("Play random track"));
        var previous_button = new Gtk.Button.from_icon_name("media-skip-backward-symbolic");
        var next_button = new Gtk.Button.from_icon_name("media-skip-forward-symbolic");
        var pause_button = new Gtk.Button.from_icon_name("media-playback-pause-symbolic");
        var play_button = new Gtk.Button.from_icon_name("media-playback-start-symbolic");
        var volume_slider = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 1, 0.05);
        var show_notif_toggle = new Gtk.Switch ();
        show_notif_toggle.set_active(true);
        var show_notif_label = new Gtk.Label(_("Show notifications"));
        var link_button = new Gtk.LinkButton.with_label ("https://audius.co/trending", _("Open this track on Audius.co"));
        
        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.row_spacing = 6;
        grid.column_spacing = 6;
        // Very sketchy padding work here buddy
        var padding_left = new Gtk.Label (_(" "));
        var padding_right = new Gtk.Label (_(" "));
        grid.attach(padding_left, -1, 99, 1, 1);
        grid.attach(padding_right, 2, 99, 1, 1);
        grid.add (search_label);
        grid.add (search_entry);
        grid.add (search_results);
        grid.add (title_label);
        grid.add (playing_label);
        grid.add (album_art);
        var duration = new Gtk.Grid ();
        duration.attach(duration_label, 0, 0, 1, 1);
        duration.attach(duration_slider, 1, 0, 3, 1);
        duration.attach(duration_full, 4, 0, 1, 1);
        grid.add(duration);
        grid.add (random_button);
        var buttons = new Gtk.Grid ();
        buttons.attach(previous_button, 0, 0, 1, 1);
        buttons.attach(pause_button, 1, 0, 1, 1);
        buttons.attach(play_button, 1, 0, 1, 1);
        buttons.attach(next_button, 2, 0, 1, 1);
        grid.add(buttons);
        grid.add (volume_slider);
        var notif_grid = new Gtk.Grid ();
        notif_grid.column_spacing = 6;
        // var notif_padding = new Gtk.Label (_(" "));
        notif_grid.attach(show_notif_toggle, 0, 0, 1, 1);
        // notif_grid.attach(notif_padding, 1, 0, 1, 1);
        notif_grid.attach(show_notif_label, 2, 0, 1, 1);
        grid.add (notif_grid);
        grid.add (link_button);

        search_entry.set_hexpand (true);
        title_label.set_hexpand (true);
        playing_label.set_hexpand (true);
        playing_label.set_line_wrap(true);
        playing_label.set_justify (Gtk.Justification.CENTER);
        album_art.set_hexpand (true);
        duration_label.set_hexpand (true);
        duration_slider.set_hexpand (true);
        duration_full.set_hexpand (true);
        random_button.set_hexpand (true);
        previous_button.set_hexpand (true);
        next_button.set_hexpand (true);
        play_button.set_hexpand (true);
        pause_button.set_hexpand (true);
        show_notif_label.set_justify (Gtk.Justification.LEFT);
        link_button.set_hexpand (false);
        duration_slider.set_draw_value (false);
        volume_slider.set_draw_value (false);

        random_button.clicked.connect (() => {
            play(ref link_button, ref playing_label, ref album_art, false);
        });
        previous_button.clicked.connect (() => {
            play(ref link_button, ref playing_label, ref album_art, true, -1);
        });
        next_button.clicked.connect (() => {
            play(ref link_button, ref playing_label, ref album_art, true, 1);
        });
        pause_button.clicked.connect (() => {
            pause_or_play(ref link_button, ref playing_label, ref album_art, ref pause_button, ref play_button);
        });
        play_button.clicked.connect (() => {
            pause_or_play(ref link_button, ref playing_label, ref album_art, ref pause_button, ref play_button);
        });
        show_notif_toggle.state_set.connect (() => {
            show_notifications = !show_notif_toggle.get_state();
            return false;
        });

        search_results.set_selection_mode(Gtk.SelectionMode.SINGLE);

        main_window.add (grid);
        main_window.show_all ();
        //search_results.hide ();
        pause_button.hide ();
        buttons.hide ();
        duration_slider.hide ();

        bool is_ready = false;
        var track_time = new TimeoutSource(1000);

        player = new StreamPlayer (ref is_ready, ref track_time);

        track_time.attach(null);

        duration_slider.change_value.connect ((scroll, new_value) => {
            player.seek(new_value/1000.0);
            return false;
        });
        volume_slider.change_value.connect ((scroll, new_value) => {
            // Good enough approximation
            player.set_volume(Math.pow(new_value, 4));
            return false;
        });
        player.set_volume(Math.pow(0.5, 4));
        volume_slider.adjustment.value = 0.5;
        search_results.row_activated.connect ((row) => {
            var usr = m_results[row.get_index()];
            player.set_user(usr);
            search_results.hide();
            main_window.resize(280, 300);
        });

        player.song_changed.connect (() => {
            duration_slider.show();
            var some_track = player.get_current_track ();

            link_button.set_uri("https://audius.co/tracks/"+some_track.id);
    
            playing_label.set_label(some_track.user.name + " - " + some_track.title);
            album_art.set_from_pixbuf(player.get_current_track_image ());

            update_duration_bar (player.current_seconds, some_track.duration, ref duration_label, ref duration_slider, ref duration_full);
    
            show_notification(some_track.title, "By " + some_track.user.name);
        });
        player.playlist_changed.connect ((name) => {
            title_label.set_label(_("Now playing from " + name + ":"));
        });
        player.play_state_changed.connect ((new_state) => {
            if (new_state != Gst.State.PLAYING) {
                pause_button.hide();
                play_button.show();
            } else {
                play_button.hide();
                pause_button.show();
            }
        });
        player.has_notification.connect ((title, body, icon) => {
            show_notification(title, body, icon);
        });
        player.duration_tick.connect ((current_seconds) => {
            update_duration_bar (current_seconds, (player.get_current_track ()).duration, ref duration_label, ref duration_slider, ref duration_full);
        });
        player.song_ended.connect (() => {
            play(ref link_button, ref playing_label, ref album_art, true, 1);
        });
        player.search_query_done.connect ((results) => {
            search_results.foreach((w) => {
                search_results.remove(w);
            });
            m_results = results;
            for (var i = 0; i < m_results.size; i++) {
                var row = new Gtk.ListBoxRow();
                var label = new Gtk.Label(_(m_results[i].name));
                row.add(label);
                search_results.add(row);
            }
            search_results.show();
            grid.show();
            main_window.show_all ();
            if (!player.is_playing()) {
                pause_button.hide();
                play_button.show();
            } else {
                play_button.hide();
                pause_button.show();
            }
        });
        player.search_query.connect (() => {
            return search_entry.get_text ();
        });
        player.api_is_ready.connect (() => {
            playing_label.set_label("");
            buttons.show();
            // smelly code :(
            var some_track = player.get_current_track ();
            link_button.set_uri("https://audius.co/tracks/"+some_track.id);
            playing_label.set_label(some_track.user.name + " - " + some_track.title);
            album_art.set_from_pixbuf(player.get_current_track_image ());
            duration_slider.show();
            update_duration_bar (player.current_seconds, some_track.duration, ref duration_label, ref duration_slider, ref duration_full);
        });
/*
        var time = new TimeoutSource(100);
        time.set_callback(() => {
            if (is_ready) {
                playing_label.set_label("");
                buttons.show();
                Gtk.main_quit();
                return false;
            }
            return true;
        });
        time.attach(null);

        Gtk.main();*/
    }

    public static int main (string[] args) {
        Gst.init (ref args);
        var app = new Application ();
        return app.run (args);
    }
}

