[libevent](http://libevent.org) is usually used as substitution for [select](http://en.wikipedia.org/wiki/Select_(Unix)) system call to write efficient and portable code. A benefit of libevent is, besides normal fd, it enables monitoring signal, timeout and user supplied event in a **consistent** manner.
Typically, the code makes use of libevent has the below structure:

![libevent_code_structure](http://farm9.staticflickr.com/8066/8216290243_570811d5e5.jpg)

In the final step, we call [event_base_dispatch](http://www.wangafu.net/~nickm/libevent-2.0/doxygen/html/event_8h.html#a01e457364ed5216a8c7bc219033b946f) function which will run a loop on current thread until there is no more events to handle. Since the thread is busy running the loop, if we want to active an user event, we must do it in a new thread. We should notice that in libevent, we must explicitly set threading support via the [evthread_use_pthreads](http://www.wangafu.net/~nickm/libevent-2.0/doxygen/html/thread_8h.html#a6b2f9d2502cbf13063f5bfe0c3c8ff73) or [evthread_use_windows_threads](http://www.wangafu.net/~nickm/libevent-2.0/doxygen/html/thread_8h.html#ae6227c318642f9af248897bab1a0aa58), and we should call [evthread_make_base_notifiable](http://www.wangafu.net/~nickm/libevent-2.0/doxygen/html/thread_8h.html#ad6ce3b3efff53b41758944a8b486f62c) function so that event_base can be notified by events on another thread. So, in order to use user event, we need to following things:

1. Create an event struct for user event, and add it to the event_base
1. Prepare threading for event_base by calling evthread_use_pthreads/evthread_use_windows_threads and evthread_make_base_notifiable
1. Start a new thread, and monitor if the user event should be fired
1. Call event_active on the user event if the firing condition has been satisfied
The structure is shown below:

![libevent_user_event_code_structure](http://farm9.staticflickr.com/8343/8217375730_946699ab4e_b.jpg)

And here is sample code.

<div style="background-color: #000040; color: silver;">
<font face="monospace">
<font color="#ffff00"><b>&nbsp;&nbsp;1&nbsp;</b></font><font color="#00ffff"><b>/*</b></font><br>
<font color="#ffff00"><b>&nbsp;&nbsp;2&nbsp;</b></font><font color="#00ffff"><b>&nbsp;&nbsp;This exmple program provides a trivial server program that listens for TCP</b></font><br>
<font color="#ffff00"><b>&nbsp;&nbsp;3&nbsp;</b></font><font color="#00ffff"><b>&nbsp;&nbsp;connections on port 9995.&nbsp;&nbsp;When they arrive, it writes a short message to</b></font><br>
<font color="#ffff00"><b>&nbsp;&nbsp;4&nbsp;</b></font><font color="#00ffff"><b>&nbsp;&nbsp;each client connection, and closes each connection once it is flushed.</b></font><br>
<font color="#ffff00"><b>&nbsp;&nbsp;5&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;&nbsp;6&nbsp;</b></font><font color="#00ffff"><b>&nbsp;&nbsp;Where possible, it exits cleanly in response to a SIGINT (ctrl-c).</b></font><br>
<font color="#ffff00"><b>&nbsp;&nbsp;7&nbsp;</b></font><font color="#00ffff"><b>*/</b></font><br>
<font color="#ffff00"><b>&nbsp;&nbsp;8&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;&nbsp;9&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;10&nbsp;</b></font><font color="#8080ff"><b>#include&nbsp;</b></font><font color="#ff40ff"><b>&lt;string.h&gt;</b></font><br>
<font color="#ffff00"><b>&nbsp;11&nbsp;</b></font><font color="#8080ff"><b>#include&nbsp;</b></font><font color="#ff40ff"><b>&lt;errno.h&gt;</b></font><br>
<font color="#ffff00"><b>&nbsp;12&nbsp;</b></font><font color="#8080ff"><b>#include&nbsp;</b></font><font color="#ff40ff"><b>&lt;stdio.h&gt;</b></font><br>
<font color="#ffff00"><b>&nbsp;13&nbsp;</b></font><font color="#8080ff"><b>#include&nbsp;</b></font><font color="#ff40ff"><b>&lt;signal.h&gt;</b></font><br>
<font color="#ffff00"><b>&nbsp;14&nbsp;</b></font><font color="#8080ff"><b>#ifndef _WIN32</b></font><br>
<font color="#ffff00"><b>&nbsp;15&nbsp;</b></font><font color="#8080ff"><b>#include&nbsp;</b></font><font color="#ff40ff"><b>&lt;netinet/in.h&gt;</b></font><br>
<font color="#ffff00"><b>&nbsp;16&nbsp;</b></font><font color="#8080ff"><b># ifdef _XOPEN_SOURCE_EXTENDED</b></font><br>
<font color="#ffff00"><b>&nbsp;17&nbsp;</b></font><font color="#8080ff"><b>#&nbsp;&nbsp;include&nbsp;</b></font><font color="#ff40ff"><b>&lt;arpa/inet.h&gt;</b></font><br>
<font color="#ffff00"><b>&nbsp;18&nbsp;</b></font><font color="#8080ff"><b># endif</b></font><br>
<font color="#ffff00"><b>&nbsp;19&nbsp;</b></font><font color="#8080ff"><b>#include&nbsp;</b></font><font color="#ff40ff"><b>&lt;sys/socket.h&gt;</b></font><br>
<font color="#ffff00"><b>&nbsp;20&nbsp;</b></font><font color="#8080ff"><b>#endif</b></font><br>
<font color="#ffff00"><b>&nbsp;21&nbsp;</b></font><font color="#8080ff"><b>#include&nbsp;</b></font><font color="#ff40ff"><b>&lt;pthread.h&gt;</b></font><br>
<font color="#ffff00"><b>&nbsp;22&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;23&nbsp;</b></font><font color="#8080ff"><b>#include&nbsp;</b></font><font color="#ff40ff"><b>&lt;event2/bufferevent.h&gt;</b></font><br>
<font color="#ffff00"><b>&nbsp;24&nbsp;</b></font><font color="#8080ff"><b>#include&nbsp;</b></font><font color="#ff40ff"><b>&lt;event2/buffer.h&gt;</b></font><br>
<font color="#ffff00"><b>&nbsp;25&nbsp;</b></font><font color="#8080ff"><b>#include&nbsp;</b></font><font color="#ff40ff"><b>&lt;event2/listener.h&gt;</b></font><br>
<font color="#ffff00"><b>&nbsp;26&nbsp;</b></font><font color="#8080ff"><b>#include&nbsp;</b></font><font color="#ff40ff"><b>&lt;event2/util.h&gt;</b></font><br>
<font color="#ffff00"><b>&nbsp;27&nbsp;</b></font><font color="#8080ff"><b>#include&nbsp;</b></font><font color="#ff40ff"><b>&lt;event2/event.h&gt;</b></font><br>
<font color="#ffff00"><b>&nbsp;28&nbsp;</b></font><font color="#8080ff"><b>#include&nbsp;</b></font><font color="#ff40ff"><b>&lt;event2/thread.h&gt;</b></font><br>
<font color="#ffff00"><b>&nbsp;29&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;30&nbsp;</b></font><font color="#00ff00"><b>static</b></font>&nbsp;<font color="#00ff00"><b>const</b></font>&nbsp;<font color="#00ff00"><b>char</b></font>&nbsp;MESSAGE[] =&nbsp;<font color="#ff40ff"><b>&quot;Hello, World!</b></font><font color="#ff6060"><b>\n</b></font><font color="#ff40ff"><b>&quot;</b></font>;<br>
<font color="#ffff00"><b>&nbsp;31&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;32&nbsp;</b></font><font color="#00ff00"><b>static</b></font>&nbsp;<font color="#00ff00"><b>const</b></font>&nbsp;<font color="#00ff00"><b>int</b></font>&nbsp;PORT =&nbsp;<font color="#ff40ff"><b>9995</b></font>;<br>
<font color="#ffff00"><b>&nbsp;33&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;34&nbsp;</b></font><font color="#00ff00"><b>static</b></font>&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;listener_cb(<font color="#00ff00"><b>struct</b></font>&nbsp;evconnlistener *, evutil_socket_t,<br>
<font color="#ffff00"><b>&nbsp;35&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;sockaddr *,&nbsp;<font color="#00ff00"><b>int</b></font>&nbsp;socklen,&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;*);<br>
<font color="#ffff00"><b>&nbsp;36&nbsp;</b></font><font color="#00ff00"><b>static</b></font>&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;conn_readcb(<font color="#00ff00"><b>struct</b></font>&nbsp;bufferevent *,&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;*);<br>
<font color="#ffff00"><b>&nbsp;37&nbsp;</b></font><font color="#00ff00"><b>static</b></font>&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;conn_writecb(<font color="#00ff00"><b>struct</b></font>&nbsp;bufferevent *,&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;*);<br>
<font color="#ffff00"><b>&nbsp;38&nbsp;</b></font><font color="#00ff00"><b>static</b></font>&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;conn_eventcb(<font color="#00ff00"><b>struct</b></font>&nbsp;bufferevent *,&nbsp;<font color="#00ff00"><b>short</b></font>,&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;*);<br>
<font color="#ffff00"><b>&nbsp;39&nbsp;</b></font><font color="#00ff00"><b>static</b></font>&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;signal_cb(evutil_socket_t,&nbsp;<font color="#00ff00"><b>short</b></font>,&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;*);<br>
<font color="#ffff00"><b>&nbsp;40&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;41&nbsp;</b></font><font color="#00ff00"><b>static</b></font>&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;event* init_user_event(<font color="#00ff00"><b>struct</b></font>&nbsp;event_base*);<br>
<font color="#ffff00"><b>&nbsp;42&nbsp;</b></font><font color="#00ff00"><b>static</b></font>&nbsp;<font color="#00ff00"><b>void</b></font>* user_event_proc(<font color="#00ff00"><b>void</b></font>*);<br>
<font color="#ffff00"><b>&nbsp;43&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;44&nbsp;</b></font><font color="#00ff00"><b>int</b></font>&nbsp;main(<font color="#00ff00"><b>int</b></font>&nbsp;argc,&nbsp;<font color="#00ff00"><b>char</b></font>&nbsp;**argv) {<br>
<font color="#ffff00"><b>&nbsp;45&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;event_base *base;<br>
<font color="#ffff00"><b>&nbsp;46&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;evconnlistener *listener;<br>
<font color="#ffff00"><b>&nbsp;47&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;event *signal_event, *user_event;<br>
<font color="#ffff00"><b>&nbsp;48&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;pthread_t th;<br>
<font color="#ffff00"><b>&nbsp;49&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;50&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;sockaddr_in sin;<br>
<font color="#ffff00"><b>&nbsp;51&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>int</b></font>&nbsp;rc =&nbsp;<font color="#ff40ff"><b>0</b></font>;<br>
<font color="#ffff00"><b>&nbsp;52&nbsp;</b></font><font color="#8080ff"><b>#ifdef _WIN32</b></font><br>
<font color="#ffff00"><b>&nbsp;53&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;WSADATA wsa_data;<br>
<font color="#ffff00"><b>&nbsp;54&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;WSAStartup(<font color="#ff40ff"><b>0x0201</b></font>, &amp;wsa_data);<br>
<font color="#ffff00"><b>&nbsp;55&nbsp;</b></font><font color="#8080ff"><b>#endif</b></font><br>
<font color="#ffff00"><b>&nbsp;56&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;57&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;base = event_base_new();<br>
<font color="#ffff00"><b>&nbsp;58&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>if</b></font>&nbsp;(!base) {<br>
<font color="#ffff00"><b>&nbsp;59&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fprintf(<font color="#ff40ff"><b>stderr</b></font>,&nbsp;<font color="#ff40ff"><b>&quot;Could not initialize libevent!</b></font><font color="#ff6060"><b>\n</b></font><font color="#ff40ff"><b>&quot;</b></font>);<br>
<font color="#ffff00"><b>&nbsp;60&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>return</b></font>&nbsp;<font color="#ff40ff"><b>1</b></font>;<br>
<font color="#ffff00"><b>&nbsp;61&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<font color="#ffff00"><b>&nbsp;62&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;63&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;evthread_use_pthreads();<br>
<font color="#ffff00"><b>&nbsp;64&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>if</b></font>&nbsp;(evthread_make_base_notifiable(base)&lt;<font color="#ff40ff"><b>0</b></font>) {<br>
<font color="#ffff00"><b>&nbsp;65&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;printf(<font color="#ff40ff"><b>&quot;Couldn't make base notifiable!&quot;</b></font>);<br>
<font color="#ffff00"><b>&nbsp;66&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>return</b></font>&nbsp;<font color="#ff40ff"><b>1</b></font>;<br>
<font color="#ffff00"><b>&nbsp;67&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<font color="#ffff00"><b>&nbsp;68&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;memset(&amp;sin,&nbsp;<font color="#ff40ff"><b>0</b></font>,&nbsp;<font color="#ffff00"><b>sizeof</b></font>(sin));<br>
<font color="#ffff00"><b>&nbsp;69&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;sin.sin_family = AF_INET;<br>
<font color="#ffff00"><b>&nbsp;70&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;sin.sin_port = htons(PORT);<br>
<font color="#ffff00"><b>&nbsp;71&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;72&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;listener = evconnlistener_new_bind(base, listener_cb, (<font color="#00ff00"><b>void</b></font>&nbsp;*)base,<br>
<font color="#ffff00"><b>&nbsp;73&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;LEV_OPT_REUSEABLE|LEV_OPT_CLOSE_ON_FREE, -<font color="#ff40ff"><b>1</b></font>,<br>
<font color="#ffff00"><b>&nbsp;74&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(<font color="#00ff00"><b>struct</b></font>&nbsp;sockaddr*)&amp;sin,<br>
<font color="#ffff00"><b>&nbsp;75&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>sizeof</b></font>(sin));<br>
<font color="#ffff00"><b>&nbsp;76&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;77&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>if</b></font>&nbsp;(!listener) {<br>
<font color="#ffff00"><b>&nbsp;78&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fprintf(<font color="#ff40ff"><b>stderr</b></font>,&nbsp;<font color="#ff40ff"><b>&quot;Could not create a listener!</b></font><font color="#ff6060"><b>\n</b></font><font color="#ff40ff"><b>&quot;</b></font>);<br>
<font color="#ffff00"><b>&nbsp;79&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>return</b></font>&nbsp;<font color="#ff40ff"><b>1</b></font>;<br>
<font color="#ffff00"><b>&nbsp;80&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<font color="#ffff00"><b>&nbsp;81&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;82&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;signal_event = evsignal_new(base,&nbsp;<font color="#ff40ff"><b>SIGINT</b></font>, signal_cb, (<font color="#00ff00"><b>void</b></font>&nbsp;*)base);<br>
<font color="#ffff00"><b>&nbsp;83&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;84&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>if</b></font>&nbsp;(!signal_event || event_add(signal_event,&nbsp;<font color="#ff40ff"><b>NULL</b></font>)&lt;<font color="#ff40ff"><b>0</b></font>) {<br>
<font color="#ffff00"><b>&nbsp;85&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fprintf(<font color="#ff40ff"><b>stderr</b></font>,&nbsp;<font color="#ff40ff"><b>&quot;Could not create/add a signal event!</b></font><font color="#ff6060"><b>\n</b></font><font color="#ff40ff"><b>&quot;</b></font>);<br>
<font color="#ffff00"><b>&nbsp;86&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>return</b></font>&nbsp;<font color="#ff40ff"><b>1</b></font>;<br>
<font color="#ffff00"><b>&nbsp;87&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<font color="#ffff00"><b>&nbsp;88&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;user_event = init_user_event(base);<br>
<font color="#ffff00"><b>&nbsp;89&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;pthread_create(&amp;th,&nbsp;<font color="#ff40ff"><b>NULL</b></font>, user_event_proc, user_event);<br>
<font color="#ffff00"><b>&nbsp;90&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;91&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ffff"><b>/*</b></font><font color="#00ffff"><b>rc = event_base_loop(base, EVLOOP_NO_EXIT_ON_EMPTY);</b></font><font color="#00ffff"><b>*/</b></font><br>
<font color="#ffff00"><b>&nbsp;92&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;event_base_dispatch(base);<br>
<font color="#ffff00"><b>&nbsp;93&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;94&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;evconnlistener_free(listener);<br>
<font color="#ffff00"><b>&nbsp;95&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;event_free(signal_event);<br>
<font color="#ffff00"><b>&nbsp;96&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;event_free(user_event);<br>
<font color="#ffff00"><b>&nbsp;97&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;event_base_free(base);<br>
<font color="#ffff00"><b>&nbsp;98&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;99&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;printf(<font color="#ff40ff"><b>&quot;done</b></font><font color="#ff6060"><b>\n</b></font><font color="#ff40ff"><b>&quot;</b></font>);<br>
<font color="#ffff00"><b>100&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>return</b></font>&nbsp;<font color="#ff40ff"><b>0</b></font>;<br>
<font color="#ffff00"><b>101&nbsp;</b></font>}<br>
<font color="#ffff00"><b>102&nbsp;</b></font><br>
<font color="#ffff00"><b>103&nbsp;</b></font><font color="#00ff00"><b>static</b></font>&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;listener_cb(<font color="#00ff00"><b>struct</b></font>&nbsp;evconnlistener *listener, evutil_socket_t fd,<br>
<font color="#ffff00"><b>104&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;sockaddr *sa,&nbsp;<font color="#00ff00"><b>int</b></font>&nbsp;socklen,&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;*user_data) {<br>
<font color="#ffff00"><b>105&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;event_base *base = (<font color="#00ff00"><b>struct</b></font>&nbsp;event_base*)user_data;<br>
<font color="#ffff00"><b>106&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;bufferevent *bev;<br>
<font color="#ffff00"><b>107&nbsp;</b></font><br>
<font color="#ffff00"><b>108&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;bev = bufferevent_socket_new(base, fd, BEV_OPT_CLOSE_ON_FREE);<br>
<font color="#ffff00"><b>109&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>if</b></font>&nbsp;(!bev) {<br>
<font color="#ffff00"><b>110&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fprintf(<font color="#ff40ff"><b>stderr</b></font>,&nbsp;<font color="#ff40ff"><b>&quot;Error constructing bufferevent!&quot;</b></font>);<br>
<font color="#ffff00"><b>111&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;event_base_loopbreak(base);<br>
<font color="#ffff00"><b>112&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>return</b></font>;<br>
<font color="#ffff00"><b>113&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<font color="#ffff00"><b>114&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;bufferevent_setcb(bev, conn_readcb, conn_writecb, conn_eventcb,&nbsp;<font color="#ff40ff"><b>NULL</b></font>);<br>
<font color="#ffff00"><b>115&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;bufferevent_enable(bev, EV_WRITE);<br>
<font color="#ffff00"><b>116&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;bufferevent_enable(bev, EV_READ);<br>
<font color="#ffff00"><b>117&nbsp;</b></font><br>
<font color="#ffff00"><b>118&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ffff"><b>/*</b></font><font color="#00ffff"><b>bufferevent_write(bev, MESSAGE, strlen(MESSAGE));</b></font><font color="#00ffff"><b>*/</b></font><br>
<font color="#ffff00"><b>119&nbsp;</b></font>}<br>
<font color="#ffff00"><b>120&nbsp;</b></font><br>
<font color="#ffff00"><b>121&nbsp;</b></font><font color="#00ff00"><b>static</b></font>&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;conn_readcb(<font color="#00ff00"><b>struct</b></font>&nbsp;bufferevent *bev,&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;*) {<br>
<font color="#ffff00"><b>122&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;evbuffer *input = bufferevent_get_input(bev);<br>
<font color="#ffff00"><b>123&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;printf(<font color="#ff40ff"><b>&quot;readcb</b></font><font color="#ff6060"><b>\n</b></font><font color="#ff40ff"><b>&quot;</b></font>);<br>
<font color="#ffff00"><b>124&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>int</b></font>&nbsp;len = evbuffer_get_length(input);<br>
<font color="#ffff00"><b>125&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>if</b></font>&nbsp;(len !=&nbsp;<font color="#ff40ff"><b>0</b></font>) {<br>
<font color="#ffff00"><b>126&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;printf(<font color="#ff40ff"><b>&quot;readcb parse_message</b></font><font color="#ff6060"><b>\n</b></font><font color="#ff40ff"><b>&quot;</b></font>);<br>
<font color="#ffff00"><b>127&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>char</b></font>* buf = new&nbsp;<font color="#00ff00"><b>char</b></font>[len]();<br>
<font color="#ffff00"><b>128&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;evbuffer_copyout(input, buf, len);<br>
<font color="#ffff00"><b>129&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;delete[] buf;<br>
<font color="#ffff00"><b>130&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<font color="#ffff00"><b>131&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;bufferevent_write(bev, MESSAGE, strlen(MESSAGE));<br>
<font color="#ffff00"><b>132&nbsp;</b></font>}<br>
<font color="#ffff00"><b>133&nbsp;</b></font><br>
<font color="#ffff00"><b>134&nbsp;</b></font><font color="#00ff00"><b>static</b></font>&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;conn_writecb(<font color="#00ff00"><b>struct</b></font>&nbsp;bufferevent *bev,&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;*user_data) {<br>
<font color="#ffff00"><b>135&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;evbuffer *output = bufferevent_get_output(bev);<br>
<font color="#ffff00"><b>136&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>if</b></font>&nbsp;(evbuffer_get_length(output) ==&nbsp;<font color="#ff40ff"><b>0</b></font>) {<br>
<font color="#ffff00"><b>137&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;printf(<font color="#ff40ff"><b>&quot;flushed answer</b></font><font color="#ff6060"><b>\n</b></font><font color="#ff40ff"><b>&quot;</b></font>);<br>
<font color="#ffff00"><b>138&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ffff"><b>/*</b></font><font color="#00ffff"><b>bufferevent_free(bev);</b></font><font color="#00ffff"><b>*/</b></font><br>
<font color="#ffff00"><b>139&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<font color="#ffff00"><b>140&nbsp;</b></font>}<br>
<font color="#ffff00"><b>141&nbsp;</b></font><br>
<font color="#ffff00"><b>142&nbsp;</b></font><font color="#00ff00"><b>static</b></font>&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;conn_eventcb(<font color="#00ff00"><b>struct</b></font>&nbsp;bufferevent *bev,&nbsp;<font color="#00ff00"><b>short</b></font>&nbsp;events,&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;*user_data) {<br>
<font color="#ffff00"><b>143&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>if</b></font>&nbsp;(events &amp; BEV_EVENT_EOF) {<br>
<font color="#ffff00"><b>144&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;printf(<font color="#ff40ff"><b>&quot;Connection closed.</b></font><font color="#ff6060"><b>\n</b></font><font color="#ff40ff"><b>&quot;</b></font>);<br>
<font color="#ffff00"><b>145&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;}&nbsp;<font color="#ffff00"><b>else</b></font>&nbsp;<font color="#ffff00"><b>if</b></font>&nbsp;(events &amp; BEV_EVENT_ERROR) {<br>
<font color="#ffff00"><b>146&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;printf(<font color="#ff40ff"><b>&quot;Got an error on the connection:&nbsp;</b></font><font color="#ff6060"><b>%s</b></font><font color="#ff6060"><b>\n</b></font><font color="#ff40ff"><b>&quot;</b></font>,<br>
<font color="#ffff00"><b>147&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;strerror(errno));<font color="#00ffff"><b>/*</b></font><span style="background-color: #ffff00"><font color="#808080">XXX</font></span><font color="#00ffff"><b>&nbsp;win32</b></font><font color="#00ffff"><b>*/</b></font><br>
<font color="#ffff00"><b>148&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<font color="#ffff00"><b>149&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ffff"><b>/*</b></font><font color="#00ffff"><b>&nbsp;None of the other events can happen here, since we haven't enabled</b></font><br>
<font color="#ffff00"><b>150&nbsp;</b></font><font color="#00ffff"><b>&nbsp;&nbsp;&nbsp;&nbsp; * timeouts&nbsp;</b></font><font color="#00ffff"><b>*/</b></font><br>
<font color="#ffff00"><b>151&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;bufferevent_free(bev);<br>
<font color="#ffff00"><b>152&nbsp;</b></font>}<br>
<font color="#ffff00"><b>153&nbsp;</b></font><br>
<font color="#ffff00"><b>154&nbsp;</b></font><font color="#00ff00"><b>static</b></font>&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;signal_cb(evutil_socket_t sig,&nbsp;<font color="#00ff00"><b>short</b></font>&nbsp;events,&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;*user_data) {<br>
<font color="#ffff00"><b>155&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;event_base *base = (<font color="#00ff00"><b>struct</b></font>&nbsp;event_base*)user_data;<br>
<font color="#ffff00"><b>156&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;timeval delay = {&nbsp;<font color="#ff40ff"><b>1</b></font>,&nbsp;<font color="#ff40ff"><b>0</b></font>&nbsp;};<br>
<font color="#ffff00"><b>157&nbsp;</b></font><br>
<font color="#ffff00"><b>158&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;printf(<font color="#ff40ff"><b>&quot;Caught an interrupt signal; exiting cleanly in one second.</b></font><font color="#ff6060"><b>\n</b></font><font color="#ff40ff"><b>&quot;</b></font>);<br>
<font color="#ffff00"><b>159&nbsp;</b></font><br>
<font color="#ffff00"><b>160&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;event_base_loopexit(base, &amp;delay);<br>
<font color="#ffff00"><b>161&nbsp;</b></font>}<br>
<font color="#ffff00"><b>162&nbsp;</b></font><br>
<font color="#ffff00"><b>163&nbsp;</b></font><font color="#00ff00"><b>static</b></font>&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;user_event_cb(evutil_socket_t,&nbsp;<font color="#00ff00"><b>short</b></font>&nbsp;events,&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;*user_data) {<br>
<font color="#ffff00"><b>164&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;printf(<font color="#ff40ff"><b>&quot;user event&nbsp;</b></font><font color="#ff6060"><b>%04x</b></font><font color="#ff40ff"><b>&nbsp;fired!!!!!</b></font><font color="#ff6060"><b>\n</b></font><font color="#ff40ff"><b>&quot;</b></font>, events);<br>
<font color="#ffff00"><b>165&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;event_base *base = (<font color="#00ff00"><b>struct</b></font>&nbsp;event_base*)user_data;<br>
<font color="#ffff00"><b>166&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ffff"><b>/*</b></font><font color="#00ffff"><b>event_base_dump_events(base, stdout);</b></font><font color="#00ffff"><b>*/</b></font><br>
<font color="#ffff00"><b>167&nbsp;</b></font>}<br>
<font color="#ffff00"><b>168&nbsp;</b></font><br>
<font color="#ffff00"><b>169&nbsp;</b></font><font color="#00ff00"><b>static</b></font>&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;event* init_user_event(<font color="#00ff00"><b>struct</b></font>&nbsp;event_base* base) {<br>
<font color="#ffff00"><b>170&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;event *ev_user =&nbsp;<font color="#ff40ff"><b>NULL</b></font>;<br>
<font color="#ffff00"><b>171&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;timeval timeout = {&nbsp;<font color="#ff40ff"><b>2</b></font>,&nbsp;<font color="#ff40ff"><b>0</b></font>&nbsp;};<br>
<font color="#ffff00"><b>172&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;ev_user = event_new(base, -<font color="#ff40ff"><b>1</b></font>, EV_TIMEOUT|EV_READ, user_event_cb, base);<br>
<font color="#ffff00"><b>173&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ffff"><b>/*</b></font><font color="#00ffff"><b>event_add(ev_user, &amp;timeout);</b></font><font color="#00ffff"><b>*/</b></font><br>
<font color="#ffff00"><b>174&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>return</b></font>&nbsp;ev_user;<br>
<font color="#ffff00"><b>175&nbsp;</b></font>}<br>
<font color="#ffff00"><b>176&nbsp;</b></font><br>
<font color="#ffff00"><b>177&nbsp;</b></font><font color="#00ff00"><b>static</b></font>&nbsp;<font color="#00ff00"><b>void</b></font>* user_event_proc(<font color="#00ff00"><b>void</b></font>* data) {<br>
<font color="#ffff00"><b>178&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;printf(<font color="#ff40ff"><b>&quot;start user event thread</b></font><font color="#ff6060"><b>\n</b></font><font color="#ff40ff"><b>&quot;</b></font>);<br>
<font color="#ffff00"><b>179&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>struct</b></font>&nbsp;event *ev_user = (<font color="#00ff00"><b>struct</b></font>&nbsp;event*)data;<br>
<font color="#ffff00"><b>180&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>char</b></font>&nbsp;buf[<font color="#ff40ff"><b>512</b></font>] = {<font color="#ff40ff"><b>0</b></font>};<br>
<font color="#ffff00"><b>181&nbsp;</b></font><br>
<font color="#ffff00"><b>182&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>while</b></font>(<font color="#ff40ff"><b>1</b></font>) {<br>
<font color="#ffff00"><b>183&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fgets(buf,&nbsp;<font color="#ffff00"><b>sizeof</b></font>(buf),&nbsp;<font color="#ff40ff"><b>stdin</b></font>);<br>
<font color="#ffff00"><b>184&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;printf(<font color="#ff40ff"><b>&quot;read&nbsp;</b></font><font color="#ff6060"><b>%d</b></font><font color="#ff40ff"><b>&nbsp;bytes from stdio, now fire user event</b></font><font color="#ff6060"><b>\n</b></font><font color="#ff40ff"><b>&quot;</b></font>,&nbsp;<font color="#ff40ff"><b>0</b></font>);<br>
<font color="#ffff00"><b>185&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;event_active(ev_user, EV_READ|EV_WRITE,&nbsp;<font color="#ff40ff"><b>1</b></font>);<br>
<font color="#ffff00"><b>186&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<font color="#ffff00"><b>187&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>return</b></font>&nbsp;<font color="#ff40ff"><b>NULL</b></font>;<br>
<font color="#ffff00"><b>188&nbsp;</b></font>}<br>
</font>
</div>
