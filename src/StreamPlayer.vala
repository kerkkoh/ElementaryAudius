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

    const bool DEBUG = false;

    private MainLoop loop = new MainLoop ();
    dynamic Element m_play = ElementFactory.make ("playbin", "play");

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
            break;
        case MessageType.STATE_CHANGED:
            Gst.State oldstate;
            Gst.State newstate;
            Gst.State pending;
            message.parse_state_changed (out oldstate, out newstate,
                                         out pending);
                                         if (DEBUG) stdout.printf ("state changed: %s->%s:%s\n",
                           oldstate.to_string (), newstate.to_string (),
                           pending.to_string ());
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
        try {
            State state;
            State pending;
            ClockTime ct = 100000;
            StateChangeReturn succ = m_play.get_state(out state, out pending, ct);
            if (succ == StateChangeReturn.FAILURE) return false;
            return (state == State.PLAYING);
        } catch (Error e) {
            return false;
        }
    }

    public void play (string stream) {
        if (is_playing ()) stop();
        m_play = ElementFactory.make ("playbin", "play");
        m_play.uri = stream;

        Gst.Bus bus = m_play.get_bus ();
        bus.add_watch (0, bus_callback);

        m_play.set_state (State.PLAYING);

        return;
    }

    public void stop () {
        m_play.set_state (State.NULL);
    }

    public void pause () {
        if (is_playing ()) {
            m_play.set_state (State.PAUSED);
        } else {
            m_play.set_state (State.PLAYING);
        }
    }
}
