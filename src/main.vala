//  
//  Copyright (C) 2011 Adrien Plazas
// 
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//  
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
// 
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
// 
// 
//  Authors:
//      Adrien Plazas <kekun.plazas@laposte.net>
//  Artists:
//      Daniel Foré <daniel@elementaryos.org>
// 

/* TODO
 * For 0.1
 * Keep focus on terminal if terminal focused (tag FIXME)
 * 
 * For 0.2
 * Notify with system bubbles if the window is not focused (tag FIXME)
 * Set text colors ?
 * Set preferences via GSettings ? (legacy theme)
 * Use stepped window resize ? (usefull if using another terminal background color than the one from the window)
 * Start the port to the terminal background service
 * If the last page is moved to another instance, close the window ?
 */

using Gtk;
using Gdk;
using Vte;
using Pango;
//~ using Notify;

using Resources;

namespace PantheonTerminal
{
    private class PantheonTerminal : Gtk.Window
    {
		public signal void theme_changed();
		
        Notebook notebook;
        FontDescription font;
        Gdk.Color bgcolor;
        Gdk.Color fgcolor;
        
        bool window_focus = false;
        
        string[] args;
        
    //~     Notify.Notification notification;
		
		// Control and Shift keys
		bool ctrlL = false;
		bool ctrlR = false;
        bool shiftL = false;
        bool shiftR = false;
        bool arrow = false;
        
        private PantheonTerminal(string[] args)
        {
            this.args = args;
            foreach (string arg in args)
				stdout.printf("%s\n", arg);
            
//~             Gtk.Settings.get_default().gtk_application_prefer_dark_theme = true;
            set_title("Terminal");
            default_width = 640;
            default_height = 400;
            destroy.connect(close);
            
            // Check if the window have the focus
            focus_in_event.connect(() => { window_focus = true; return false; });
            focus_out_event.connect(() => { window_focus = false; return false; });
                    
            notebook = new Notebook();
            var right_box = new HBox(false, 0);
            right_box.show();
            notebook.set_action_widget(right_box, PackType.END);
            notebook.set_scrollable(true);
            add(notebook);
                        
            // Set "New tab" button
            var add_button = new Button();
            add_button.set_image(new Image.from_stock(Stock.ADD, IconSize.MENU));
            add_button.show();
            add_button.set_relief(ReliefStyle.NONE);
            add_button.set_tooltip_text("Open a new tab");
            add_button.clicked.connect(() => { new_tab(false); } );
            right_box.pack_start(add_button, false, false, 0);
                    
            // Try to set the icon FIXME
            Pixbuf icon = new Pixbuf(Colorspace.RGB, true, 8, 1, 1);
            try { IconTheme.get_default().load_icon("terminal", 16, IconLookupFlags.FORCE_SVG); } catch (Error er) {}
            set_icon(icon);
            
            // Set the theme
            set_theme();
            
            show_all();
            new_tab(true);
            
            key_press_event.connect(on_key_press_event);
            key_release_event.connect(on_key_release_event);
        }
        
        public void remove_page(int page)
        {
			notebook.remove_page(page);
			if (notebook.get_n_pages() == 0)
				new_tab(false);
		}
        
        public bool on_key_press_event(EventKey event)
		{
			
            string key = Gdk.keyval_name(event.keyval);
			if (key == "Control_L")
				ctrlL = true;
			else if (key == "Control_R")
				ctrlR = true;
            else if (key == "Shift_L")
				shiftL = true;
			else if (key == "Shift_R")
				shiftR = true;
			else if ((ctrlL || ctrlR) && (shiftL || shiftR))
			{
				if (key == "t" || key == "T")
					new_tab(false);
				else if (key == "w" || key == "W")
					remove_page(notebook.get_current_page());
				else if (key == "Tab" || key == "ISO_Left_Tab")
				{
					if (notebook.get_current_page() < notebook.get_n_pages() - 1)
						notebook.next_page();
					else
						notebook.set_current_page(0);
				}
				else if (key == "q" || key == "Q")
					close();
				else
					return false;
			}
			else if (key == "Up" || key == "Down" || key == "Left" || key == "Right")
				arrow = true;
			// stdout.printf("%s\n", key);
            return false;
        }
        
        public bool on_key_release_event(EventKey event)
		{
            string key = Gdk.keyval_name(event.keyval);
			if (key == "Control_L")
				ctrlL = false;
			else if (key == "Control_R")
				ctrlR = false;
            else if (key == "Shift_L")
				shiftL = false;
			else if (key == "Shift_R")
				shiftR = false;
			else if (key == "Up" || key == "Down" || key == "Left" || key == "Right")
				arrow = false;
            return false;
        }
        
        private void new_tab(bool first)
        {
            // Set up terminal
            var t = new TerminalWithNotification();
            if (first)
				t.fork_command_full(0, "~/", args, null, 0, null, 0);
//~ 				t.fork_command_full(PtyFlags.DEFAULT, null, null, null, SpawnFlags.FILE_AND_ARGV_ZERO, null, 0);
//~ 				t.fork_command(args[0], args, null, null, true, true, true);
			else
				t.fork_command_full(0, "~/", {}, null, 0, null, 0);
//~ 				t.fork_command_full(PtyFlags.DEFAULT, null, null, null, SpawnFlags.LEAVE_DESCRIPTORS_OPEN, null, t.get_pty());
//~ 				t.fork_command(null, null, null, null, true, true, true);
//~ 				t.forkpty(null, null, true, true, true);
			
                
            t.show();
            
            // Create a new tab with the terminal
            var tab = new TabWithCloseButton("Terminal");
            notebook.insert_page(t, tab, notebook.get_current_page() + 1);
            notebook.next_page();
            notebook.set_tab_reorderable(t, true);
            notebook.set_tab_detachable(t, true);
            
            // Set connections
            tab.clicked.connect(() => { remove_page(notebook.page_num(t)); });
            t.window_title_changed.connect(() => { tab.set_text(t.get_window_title()); });
            notebook.switch_page.connect((page, page_num) => { if (notebook.page_num(t) == (int) page_num) tab.set_notification(false); });
            focus_in_event.connect(() => { if (notebook.page_num(t) == notebook.get_current_page()) tab.set_notification(false); return false; });
            t.preferences.connect(preferences);
            t.about.connect(about);
            t.child_exited.connect(() => { t.fork_command(null, null, null, null, true, true, true); });
            theme_changed.connect(() => { set_terminal_theme(t); });
//~             t.contents_changed.connect(() => { stdout.printf("pty %i\n", t.get_pty()); });
			// Make the terminal keep the focus when arrows are pressed FIXME
            t.focus_out_event.connect((event) => {
				if (notebook.page_num(t) == notebook.get_current_page() && arrow)
				{
					t.grab_focus();
				}
				return false; });
            
            // If a task is over
            t.task_over.connect(() => {
                if (notebook.page_num(t) != notebook.get_current_page() || !window_focus)
                    tab.set_notification(true);
                if (!window_focus)
                {
                    try
                    { GLib.Process.spawn_command_line_async("notify-send \"" + t.get_window_title() + "\" \"Task over\""); }
                    catch
                    {  }
                }
    //~                 notification = (Notify.Notification)GLib.Object.new (
    //~                     typeof (Notify.Notification),
    //~                     "summary", "sum",
    //~                     "body", "message",
    //~                     "icon-name", "");
                        // Notify OSD
    //~                 notification = new Notification("test", "test", "test");
    //~                 try { notification.show(); }
    //~                 catch {}
                });
            
            // Set up style
            set_terminal_theme(t);
        }
        
        public void set_terminal_theme(TerminalWithNotification t)
		{
			t.set_font(font);
			t.set_color_background(bgcolor);
            t.set_color_foreground(fgcolor);
		}
		
		public void set_theme()
		{
			string theme = "dark";
			if (theme == "normal")
			{
				Gtk.Settings.get_default().gtk_application_prefer_dark_theme = false;
				
				// Get the system's style
				realize();
				font = FontDescription.from_string(system_font());
				bgcolor = get_style().bg[StateType.NORMAL];
				fgcolor = get_style().fg[StateType.NORMAL];
			}
			else
			{
				Gtk.Settings.get_default().gtk_application_prefer_dark_theme = true;
				
				// Get the system's style
				realize();
				font = FontDescription.from_string(system_font());
				bgcolor = get_style().bg[StateType.NORMAL];
				fgcolor = get_style().fg[StateType.NORMAL];
			}
            			
			theme_changed();
		}
		
		static string system_font()
        {
            string font_name = null;
            /* Wait for GNOME 3 FIXME
             * var settings = new GLib.Settings("org.gnome.desktop.interface");
             * font_name = settings.get_string("monospace-font-name");
             */
            font_name = "Droid Sans Mono 10";
            return font_name;
        }
        
        public void about()
        {
            show_about_dialog(this,
                "program-name", Resources.APP_TITLE,
                "version", Resources.VERSION,
                "comments", Resources.COMMENTS,
                "copyright", Resources.COPYRIGHT,
                "license", Resources.LICENSE,
                "website", Resources.WEBSITE_URL,
                "website-label",  Resources.WEBSITE_LABEL,
                "authors", Resources.AUTHORS,
                "artists", Resources.ARTISTS,
//~     				"logo", new Pixbuf.from_file(Resources.ICON_ABOUT_LOGO),
//~      				"translator-credits", _("translator-credits"), // FIXME
                null);
        }
        
        public void preferences()
        {
            stdout.printf("Preferences not yet available.\n");
        }
        
        
        private void close()
        {
            Gtk.main_quit();
        }
        
        private static void main(string[] args)
        {
            Gtk.init(ref args);
            new PantheonTerminal(args[1:args.length]);
            Gtk.main();
        }
    }
    
    public class TabWithCloseButton : HBox
    {
        public signal void clicked();
        
        private Button button;
        private Label label;
        private string text;
        bool notification = false;
        
        public TabWithCloseButton(string text)
        {
            this.text = text;
            
            // Button
            button = new Button();
            button.set_image(new Image.from_stock(Stock.CLOSE, IconSize.MENU));
            button.show();
            button.set_relief(ReliefStyle.NONE);
            button.clicked.connect(() => { clicked(); });
            
            // Label
            label = new Label(text);
            label.show();
            
            // Pack the elements
            pack_start(button, false, true, 0);
            pack_end(label, true, true, 0);
            
            show();
        }
        
        public void set_notification(bool notification)
        {
            this.notification = notification;
            if (notification)
            { label.set_markup("<span color=\"#18a0c0\">"+text+"</span>"); }
            else
            { label.set_markup(text); }
        }
        
        public void set_text(string text)
        {
            this.text = text;
            set_notification(notification);
        }
    }
}