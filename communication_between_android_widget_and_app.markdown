[Widget](http://developer.android.com/guide/topics/appwidgets/index.html) is a convienent feature in android that gives users quick access to frequently used application functions. A example is the power control widget. It helps us quickly toggling accessories such as WIFI, GPS power to conserve battery, without tedious operations.

![android power control widget](http://farm9.staticflickr.com/8195/8107979443_290c3a8d90.jpg)

When we plan to provide widget in our own application, an important thing to think about is the communication model between the widget and application. In a simiplified manner, the commucation model is shown below.

![communication model diagram](http://farm9.staticflickr.com/8054/8108016338_a5250fc0c8_b.jpg)

The widget is shown on home screen(which is a [AppWidgetHost](https://developer.android.com/reference/android/appwidget/AppWidgetHost.html)), and user can interact(e.g., touch) with the widget. The result of the interaction is either showing an activity to the user to display more information, or controlling the state of a background service. Meanwhile, the background service may proactively update the widget to inform user current state. The communication model is bidirectional.

## Launch activity from widget
To launch an activity from widget, we can use [RemoteViews](https://developer.android.com/reference/android/widget/RemoteViews.html)'s [setOnClickPendingIntent](https://developer.android.com/reference/android/widget/RemoteViews.html#setOnClickPendingIntent(int,%20android.app.PendingIntent)) method to set a intent for the target button. Once the button is clicked, the intent will be sent to start desired activity. The snippet below shows how to do this in AppWidgetProvider.


<div style="background-color: #000040; color: silver;">
<font face="monospace">
<font color="#ffff00"><b>&nbsp;1&nbsp;</b></font><font color="#8080ff"><b>import</b></font>&nbsp;android.app.PendingIntent;<br>
<font color="#ffff00"><b>&nbsp;2&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;3&nbsp;</b></font><font color="#8080ff"><b>import</b></font>&nbsp;android.appwidget.AppWidgetManager;<br>
<font color="#ffff00"><b>&nbsp;4&nbsp;</b></font><font color="#8080ff"><b>import</b></font>&nbsp;android.appwidget.AppWidgetProvider;<br>
<font color="#ffff00"><b>&nbsp;5&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;6&nbsp;</b></font><font color="#8080ff"><b>import</b></font>&nbsp;android.content.Context;<br>
<font color="#ffff00"><b>&nbsp;7&nbsp;</b></font><font color="#8080ff"><b>import</b></font>&nbsp;android.content.Intent;<br>
<font color="#ffff00"><b>&nbsp;8&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;9&nbsp;</b></font><font color="#8080ff"><b>import</b></font>&nbsp;android.widget.RemoteViews;<br>
<font color="#ffff00"><b>10&nbsp;</b></font><br>
<font color="#ffff00"><b>11&nbsp;</b></font><font color="#00ff00"><b>public</b></font>&nbsp;<font color="#00ff00"><b>class</b></font>&nbsp;GestureAppWidgetProvider&nbsp;<font color="#00ff00"><b>extends</b></font>&nbsp;AppWidgetProvider {<br>
<font color="#ffff00"><b>12&nbsp;</b></font><br>
<font color="#ffff00"><b>13&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>public</b></font>&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;onUpdate(Context context, AppWidgetManager appWidgetManager,&nbsp;<font color="#00ff00"><b>int</b></font>[]&nbsp;appWidgetIds)&nbsp;{<br>
<font color="#ffff00"><b>14&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>final</b></font>&nbsp;<font color="#00ff00"><b>int</b></font>&nbsp;N = appWidgetIds.length;<br>
<font color="#ffff00"><b>15&nbsp;</b></font><br>
<font color="#ffff00"><b>16&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ffff"><b>// Perform this loop procedure for each App Widget that belongs to this provider</b></font><br>
<font color="#ffff00"><b>17&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>for</b></font>&nbsp;(<font color="#00ff00"><b>int</b></font>&nbsp;i=<font color="#ff40ff"><b>0</b></font>; i&lt;N; i++)&nbsp;{<br>
<font color="#ffff00"><b>18&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>int</b></font>&nbsp;appWidgetId = appWidgetIds[i];<br>
<font color="#ffff00"><b>19&nbsp;</b></font><br>
<font color="#ffff00"><b>20&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ffff"><b>// Create an Intent to launch Activity</b></font><br>
<font color="#ffff00"><b>21&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Intent intent =&nbsp;<font color="#ffff00"><b>new</b></font>&nbsp;Intent(context, MainActivity.<font color="#00ff00"><b>class</b></font>);<br>
<font color="#ffff00"><b>22&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;PendingIntent pendingIntent = PendingIntent.getActivity(context,&nbsp;<font color="#ff40ff"><b>0</b></font>, intent,&nbsp;<font color="#ff40ff"><b>0</b></font>);<br>
<font color="#ffff00"><b>23&nbsp;</b></font><br>
<font color="#ffff00"><b>24&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ffff"><b>// Get the layout for the App Widget and attach an on-click listener</b></font><br>
<font color="#ffff00"><b>25&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ffff"><b>// to the button</b></font><br>
<font color="#ffff00"><b>26&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;RemoteViews views =&nbsp;<font color="#ffff00"><b>new</b></font>&nbsp;RemoteViews(context.getPackageName(), R.layout.appwidget);<br>
<font color="#ffff00"><b>27&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;views.setTextColor(R.id.startRecord, Color.GREEN);<br>
<font color="#ffff00"><b>28&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;views.setOnClickPendingIntent(R.id.startRecord, pendingIntent);<br>
<font color="#ffff00"><b>29&nbsp;</b></font><br>
<font color="#ffff00"><b>30&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ffff"><b>// Tell the AppWidgetManager to perform an update on the current app widget</b></font><br>
<font color="#ffff00"><b>31&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;appWidgetManager.updateAppWidget(appWidgetId, views);<br>
<font color="#ffff00"><b>32&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<font color="#ffff00"><b>33&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<font color="#ffff00"><b>34&nbsp;</b></font>}<br>
</font>
</div>

## Send message to service from widget

The skeleton of code to send message to a service is pretty much the same as the snippet above. The change we need to make is substitute [PendingIntent.getActivity](http://developer.android.com/reference/android/app/PendingIntent.html#getActivity(android.content.Context,%20int,%20android.content.Intent,%20int)) with [PendingIntent.getBroadCast](http://developer.android.com/reference/android/app/PendingIntent.html#getBroadcast(android.content.Context,%20int,%20android.content.Intent,%20int)). The result is once we clicked the button, a broadcast Intent will be sent, and our AppWidgetProvider(which is a subclass of [BroadcastReceiver](https://developer.android.com/reference/android/content/BroadcastReceiver.html)) will get this intent. Thie AppWidgetProvider runs in our application's process, so it can send the message to our service with [StartService](https://developer.android.com/reference/android/content/Context.html#startService(android.content.Intent)).

<div style="background-color: #000040; color: silver;">
<font face="monospace">
<font color="#ffff00"><b>&nbsp;1&nbsp;</b></font><font color="#00ff00"><b>public</b></font>&nbsp;<font color="#00ff00"><b>class</b></font>&nbsp;WeatherWidgetProvider&nbsp;<font color="#00ff00"><b>extends</b></font>&nbsp;AppWidgetProvider {<br>
<font color="#ffff00"><b>&nbsp;2&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>public</b></font>&nbsp;<font color="#00ff00"><b>static</b></font>&nbsp;String REFRESH_ACTION =&nbsp;<font color="#ff40ff"><b>&quot;com.example.android.weatherlistwidget.REFRESH&quot;</b></font>;<br>
<font color="#ffff00"><b>&nbsp;3&nbsp;</b></font><br>
<font color="#ffff00"><b>&nbsp;4&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#8080ff"><b>@Override</b></font><br>
<font color="#ffff00"><b>&nbsp;5&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>public</b></font>&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;onReceive(Context ctx, Intent intent)&nbsp;{<br>
<font color="#ffff00"><b>&nbsp;6&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>final</b></font>&nbsp;String action = intent.getAction();<br>
<font color="#ffff00"><b>&nbsp;7&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>if</b></font>&nbsp;(action.equals(REFRESH_ACTION))&nbsp;{<br>
<font color="#ffff00"><b>&nbsp;8&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ffff"><b>// send message to background service via startService here</b></font><br>
<font color="#ffff00"><b>&nbsp;9&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ffff"><b>// ..............</b></font><br>
<font color="#ffff00"><b>10&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<font color="#ffff00"><b>11&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>super</b></font>.onReceive(ctx, intent);<br>
<font color="#ffff00"><b>12&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<font color="#ffff00"><b>13&nbsp;</b></font><br>
<font color="#ffff00"><b>14&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#8080ff"><b>@Override</b></font><br>
<font color="#ffff00"><b>15&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>public</b></font>&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;onUpdate(Context context, AppWidgetManager appWidgetManager,&nbsp;<font color="#00ff00"><b>int</b></font>[]&nbsp;appWidgetIds)&nbsp;{<br>
<font color="#ffff00"><b>16&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>for</b></font>&nbsp;(<font color="#00ff00"><b>int</b></font>&nbsp;i =&nbsp;<font color="#ff40ff"><b>0</b></font>; i &lt; appWidgetIds.length; ++i)&nbsp;{<br>
<font color="#ffff00"><b>17&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>final</b></font>&nbsp;RemoteViews rv =&nbsp;<font color="#ffff00"><b>new</b></font>&nbsp;RemoteViews(context.getPackageName(), R.layout.widget_layout);<br>
<font color="#ffff00"><b>18&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;rv.setRemoteAdapter(appWidgetIds[i], R.id.weather_list, intent);<br>
<font color="#ffff00"><b>19&nbsp;</b></font><br>
<font color="#ffff00"><b>20&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ffff"><b>// Set the empty view to be displayed if the collection is empty.&nbsp;&nbsp;It must be a sibling</b></font><br>
<font color="#ffff00"><b>21&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ffff"><b>// view of the collection view.</b></font><br>
<font color="#ffff00"><b>22&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;rv.setEmptyView(R.id.weather_list, R.id.empty_view);<br>
<font color="#ffff00"><b>23&nbsp;</b></font><br>
<font color="#ffff00"><b>24&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ffff"><b>// Bind the click intent for the refresh button on the widget</b></font><br>
<font color="#ffff00"><b>25&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>final</b></font>&nbsp;Intent refreshIntent =&nbsp;<font color="#ffff00"><b>new</b></font>&nbsp;Intent(context, WeatherWidgetProvider.<font color="#00ff00"><b>class</b></font>);<br>
<font color="#ffff00"><b>26&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;refreshIntent.setAction(WeatherWidgetProvider.REFRESH_ACTION);<br>
<font color="#ffff00"><b>27&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>final</b></font>&nbsp;PendingIntent refreshPendingIntent = PendingIntent.getBroadcast(context,&nbsp;<font color="#ff40ff"><b>0</b></font>,<br>
<font color="#ffff00"><b>28&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;refreshIntent, PendingIntent.FLAG_UPDATE_CURRENT);<br>
<font color="#ffff00"><b>29&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;rv.setOnClickPendingIntent(R.id.refresh, refreshPendingIntent);<br>
<font color="#ffff00"><b>30&nbsp;</b></font><br>
<font color="#ffff00"><b>31&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;appWidgetManager.updateAppWidget(appWidgetIds[i], rv);<br>
<font color="#ffff00"><b>32&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<font color="#ffff00"><b>33&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>super</b></font>.onUpdate(context, appWidgetManager, appWidgetIds);<br>
<font color="#ffff00"><b>34&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<font color="#ffff00"><b>35&nbsp;</b></font>}<br>
</font>
</div>

## Update widget from service

To update a widget from service, we can send a broadcast message from the background service to AppWidgetProvider. Once the AppWidgetProvider receives the message, it tries to fetch current state and calls [notifyAppWidgetViewDataChanged](https://developer.android.com/reference/android/appwidget/AppWidgetManager.html#notifyAppWidgetViewDataChanged(int,%20int)) function to refresh the widget.

<div style="background-color: #000040; color: silver;">
<font face="monospace">
<font color="#ffff00"><b>1&nbsp;</b></font><font color="#00ff00"><b>public</b></font>&nbsp;<font color="#00ff00"><b>void</b></font>&nbsp;onReceive(Context ctx, Intent intent)&nbsp;{<br>
<font color="#ffff00"><b>2&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>final</b></font>&nbsp;String action = intent.getAction();<br>
<font color="#ffff00"><b>3&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#ffff00"><b>if</b></font>&nbsp;(action.equals(SHOW_NEW_DATA_ACTION))&nbsp;{<br>
<font color="#ffff00"><b>4&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>final</b></font>&nbsp;AppWidgetManager mgr = AppWidgetManager.getInstance(context);<br>
<font color="#ffff00"><b>5&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>final</b></font>&nbsp;ComponentName cn =&nbsp;<font color="#ffff00"><b>new</b></font>&nbsp;ComponentName(context, WeatherWidgetProvider.<font color="#00ff00"><b>class</b></font>);<br>
<font color="#ffff00"><b>6&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;mgr.notifyAppWidgetViewDataChanged(mgr.getAppWidgetIds(cn), R.id.weather_list);<br>
<font color="#ffff00"><b>7&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;}<br>
<font color="#ffff00"><b>8&nbsp;</b></font>&nbsp;&nbsp;&nbsp;&nbsp;<font color="#00ff00"><b>super</b></font>.onReceive(ctx, intent);<br>
<font color="#ffff00"><b>9&nbsp;</b></font>}<br>
</font>
</div>

# Reference:
android [WeatherListWidget](https://android.googlesource.com/platform/development/+/master/samples/WeatherListWidget/) sample

[Introducing home screen widgets and the AppWidget framework](http://android-developers.blogspot.com/2009/04/introducing-home-screen-widgets-and.html)

[android appwidget source code](https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/appwidget/)

[android appwidget service source code](https://android.googlesource.com/platform/frameworks/base/+/master/services/java/com/android/server/AppWidgetService.java)
