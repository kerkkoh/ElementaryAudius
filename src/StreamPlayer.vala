/*
* Idk why I'm even including this license in here. I guess no warranty? YEAH! No warranty! You heard me.
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

using Gst;

public class StreamPlayer {
    public signal void api_is_ready ();
    public signal void song_changed ();
    public signal void playlist_changed (string name);
    public signal void play_state_changed (Gst.State new_state);
    public signal void has_notification (string title, string body, string icon);
    public signal void duration_tick (int64 current_seconds, int64 duration);
    public signal void song_ended ();
    public signal string search_query ();
    public signal void search_query_done (Gee.ArrayList<User?> results);
    public bool m_initialized = false;
    public int64 current_seconds = 0;

    private string m_search_query = "";
    private string m_playing_user = "";
    private string api_endpoint;
    private Json.Array m_tracks = new Json.Array ();
    private uint track_idx = 0;
    dynamic Element m_play = ElementFactory.make ("playbin", "play");

    public int32 total_tracks () {
        return (int32) m_tracks.get_length ();
    }

    public StreamPlayer (ref bool is_ready, ref TimeoutSource track_time) {
        get_api_endpoint ();
        track_time.set_callback (() => {
            var s = search_query();
            if (s != m_search_query) {
                m_search_query = s;
                if (s == "" && m_playing_user != "") {
                    reset_user();
                } else {
                    get_search_results.begin(m_search_query, (obj, res) => {
                        get_search_results.end(res);
                    });
                }
            }
            if (is_playing ()) {
                Gst.Format fmt = Gst.Format.TIME;
                int64 current = -1;

                // Query the current position of the stream:
                if (!m_play.query_position (fmt, out current)) {
                    stderr.puts ("Could not query current position.\n");
                }
                current_seconds++;
                duration_tick (current/Gst.SECOND, (get_current_track ()).duration);
            }
            return true;
        });
    }

    private void get_api_endpoint () {
        var uri = "https://api.audius.co/";

        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", uri);
        session.queue_message (message, (sess, mess) => {
            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) mess.response_body.flatten ().data, -1);
        
                var root_object = parser.get_root ().get_object ();
                var response = root_object.get_array_member ("data");
                
                int32 total = (int32) response.get_length ();
                uint rand = (uint) GLib.Random.int_range (0, total);
    
                api_endpoint = response.get_string_element (rand);
                req_data_array_cb ("tracks/trending", "", (tracks) => {
                    m_tracks = tracks;
                    api_is_ready ();
                });
    
                if (DEBUG) stdout.printf("StreamPlayer :: api_is_ready\n");
    
                if (DEBUG) stdout.printf ("New api endpoint: %s\n", api_endpoint);
            } catch (Error e) {
                stderr.printf ("I guess something is not working...\n");
            }
        });
    }
    public delegate void DataArrayCb (Json.Array data);
    private void req_data_array_cb(string route, string query_parameters, DataArrayCb cb) {
        var session = new Soup.Session ();
        var q_params = "?app_name=ElementaryAudius";
        if (query_parameters != "") {
            q_params += query_parameters;
        }
        
        var message = new Soup.Message ("GET", api_endpoint+"/v1/"+route+q_params);
        session.queue_message (message, (sess, mess) => {
            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) message.response_body.flatten ().data, -1);
    
                var root_object = parser.get_root ().get_object ();
                cb(root_object.get_array_member ("data"));
            } catch (Error e) {
                cb(new Json.Array());
            }
        });
    }

    private Track process_track_object(Json.Object raw_track) throws Error {
        var raw_user = raw_track.get_object_member ("user");
        var raw_artwork = raw_track.get_object_member ("artwork");

        return Track() {
            artwork = Track_Artwork () {
                img_150x150 = raw_artwork.get_string_member ("150x150")//,
                //img_480x480 = raw_artwork.get_string_member ("480x480"),
                //img_1000x1000 = raw_artwork.get_string_member ("1000x1000")
            },
            id = raw_track.get_string_member ("id"),
            duration = raw_track.get_int_member ("duration"),
            title = raw_track.get_string_member ("title"),
            user = User() {
                id = raw_user.get_string_member ("id"),
                //handle = raw_user.get_string_member ("handle"),
                name = raw_user.get_string_member ("name")
            }
        };
    }
    private User process_user_object(Json.Object raw_user) throws Error {
        return User() {
            id = raw_user.get_string_member ("id"),
            name = raw_user.get_string_member ("name"),
            track_count = raw_user.get_int_member ("track_count")
        };
    }

    public Track get_current_track () throws Error {
        return process_track_object(m_tracks.get_object_element (track_idx));
    }

    private Gdk.Pixbuf get_image (string uri) {
        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", uri);
        session.send_message (message);

        var mem_ipt_stream = new GLib.MemoryInputStream.from_data(message.response_body.data);
        return new Gdk.Pixbuf.from_stream(mem_ipt_stream);
    }

    public Gdk.Pixbuf get_current_track_image () {
        return get_image((get_current_track ()).artwork.img_150x150);
    }

    public Track get_trending (bool in_order = true, int delta = 0) {
        try {
            var total = total_tracks();
            if (total == 0) {
                return Track() {title = ""};
            }
            if (in_order) {
                track_idx += delta;
            } else {
                track_idx = (uint) GLib.Random.int_range(0, total);
            }

            if (track_idx >= total) track_idx = 0;

            return get_current_track ();
        } catch (Error e) {
            has_notification ("Error...", "Something's wrong with the connection between you and Audius... Try later?", "network-error");

            return Track() {title = ""};
        }
    }

    public void seek(double position) {
        int64 sec = (int64) ((get_current_track ()).duration * position);
        m_play.seek_simple (Gst.Format.TIME, Gst.SeekFlags.FLUSH | Gst.SeekFlags.KEY_UNIT, sec * Gst.SECOND);
    }
    public void set_volume(double volume) {
        m_play.volume = volume;
    }
    public void set_user(User user) {
        var user_id = user.id;
        if (m_playing_user == user_id) return;
        m_playing_user = user_id;
        playlist_changed (user.name);
        req_data_array_cb ("users/" + user_id + "/tracks", "", (tracks) => {
            m_tracks = tracks;
            track_idx = 0;
            stop();
            play();
        });
    }
    public void reset_user() {
        if (m_playing_user == "") return;
        playlist_changed ("Trending");
        m_playing_user = "";
        req_data_array_cb ("tracks/trending", "", (tracks) => {
            m_tracks = tracks;
            track_idx = 0;
            stop();
            play();
        });
    }
    private async void get_search_results(string query) {
        req_data_array_cb ("users/search", "&query=" + query, (arr) => {
            var arrlist = new Gee.ArrayList<User?>();
            for (var i = 0; i < 4 && i < arr.get_length (); i++) {
                var usr = process_user_object(arr.get_object_element (i));
                if (usr.track_count > 0) {
                    arrlist.add(usr);
                }
            }
            search_query_done(arrlist);
        });
    }

    // Player logic

    private void foreach_tag (Gst.TagList list, string tag) {
        switch (tag) {
        case "title":
            string tag_string;
            list.get_string (tag, out tag_string);
            if (DEBUG) stdout.printf ("tag: %s = %s\n", tag, tag_string);
            break;
        default:
            break;
        }
    }

    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
        switch (message.type) {
        case MessageType.ERROR:
            GLib.Error err;
            string debug;
            message.parse_error (out err, out debug);
            if (DEBUG) stdout.printf ("Error: %s\n", err.message);
            // loop.quit ();
            break;
        case MessageType.EOS:
            // loop.quit();
            m_play.set_state (State.NULL);
            if (DEBUG) stdout.printf ("end of stream\n");
            song_ended ();
            break;
        case MessageType.STATE_CHANGED:
            Gst.State oldstate;
            Gst.State newstate;
            Gst.State pending;
            message.parse_state_changed (out oldstate, out newstate, out pending);
            if (DEBUG) stdout.printf ("state changed: %s->%s:%s\n", oldstate.to_string (), newstate.to_string (), pending.to_string ());
            play_state_changed (newstate);
            break;
        case MessageType.TAG:
            Gst.TagList tag_list;
            if (DEBUG) stdout.printf ("taglist found\n");
            message.parse_tag (out tag_list);
            tag_list.foreach ((TagForeachFunc) foreach_tag);
            break;
        default:
            break;
        }

        return true;
    }

    public bool is_playing () {
        State state;
        State pending;
        ClockTime ct = 100000;
        StateChangeReturn succ = m_play.get_state(out state, out pending, ct);
        if (succ == StateChangeReturn.FAILURE) return false;
        return (state == State.PLAYING);
    }

    public void play () {
        if (is_playing ()) stop();
        m_play = ElementFactory.make ("playbin", "play");

        m_play.uri = api_endpoint + "/v1/tracks/" + (get_current_track ()).id + "/stream";

        Gst.Bus bus = m_play.get_bus ();
        bus.add_watch (0, bus_callback);

        m_play.set_state (State.PLAYING);
        current_seconds = 0;
        //loop.run ();

        song_changed ();

        return;
    }

    public void stop () {
        m_play.set_state (State.NULL);
    }

    public void pause () {
        if (is_playing ()) {
            m_play.set_state (State.PAUSED);
            //loop.quit ();
        } else {
            m_play.set_state (State.PLAYING);
            //loop.run ();
        }
    }
}
