B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Service
Version=11.16
@EndOfDesignText@
#Region  Service Attributes 
	#StartAtBoot: True
#End Region

Sub Process_Globals	
	Private GPS As GPS
	Private TTS1 As TTS
	Private ph As Phone
	Private hg As PhoneEvents
	Private lock As PhoneWakeState
	Private Broadcast As BroadCastReceiver
	Public mqtt As MqttClient
	
	Private nid As Int = 1
	Private LastUpdateTime As Long
	Private Tracking,working As Boolean
End Sub

Sub Service_Create
	Service.AutomaticForegroundMode = Service.AUTOMATIC_FOREGROUND_NEVER
	GPS.Initialize("gps")
	lock.PartialLock
	working = True
	hg.Initialize("hg")
	TTS1.Initialize("TTS1")
	TTS1.SetLanguage("DE", "")
	Broadcast.Initialize("BR")
	Broadcast.SetPriority(2147483647)
	Broadcast.registerReceiver("android.media.VOLUME_CHANGED_ACTION")
	ConnectAndReconnect
End Sub

Sub Service_Start (StartingIntent As Intent)
	Service.StartForeground(nid, CreateNotification("..."))
	StartServiceAt(Me, DateTime.Now + 30 * DateTime.TicksPerMinute, True)
	Track
End Sub

Public Sub Track
	If Tracking Then Return
	If Starter.rp.Check(Starter.rp.PERMISSION_ACCESS_FINE_LOCATION) = False Then
		Log("No permission")
		Return
	End If
	GPS.Start(0, 0)
	Tracking = True
End Sub

Sub GPS_LocationChanged (Location1 As Location)
	If DateTime.Now > LastUpdateTime + 10 * DateTime.TicksPerSecond Then
		Dim n As Notification = CreateNotification($"$2.5{Location1.Latitude} / $2.5{Location1.Longitude}"$)
		If mqtt.Connected Then
			Dim s As String
			s = Location1.Latitude
			mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/gps/latitude",s.GetBytes("UTF8"))
			s = Location1.Longitude
			mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/gps/longitude",s.GetBytes("UTF8"))
			s = Location1.Altitude
			mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/gps/altitude",s.GetBytes("UTF8"))
			s = Location1.Speed
			mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/gps/speed",s.GetBytes("UTF8"))
		End If
		n.Notify(nid)
		LastUpdateTime = DateTime.Now
	End If
End Sub

Sub CreateNotification (Body As String) As Notification
	Dim notification As Notification
	notification.Initialize2(notification.IMPORTANCE_LOW)
	notification.Icon = "icon"
	notification.SetInfo("ioBrowser", Body, Main)
	Return notification
End Sub

Sub Service_Destroy
	If Tracking Then
		GPS.Stop
	End If
	Tracking = False
	lock.ReleasePartialLock
End Sub

Sub mqtt_MessageArrived (Topic As String, Payload() As Byte)
	Dim DP() As String = Regex.Split("/",Topic)
	Dim Point As String = DP(DP.Length - 1)
	Dim Wert As String = BytesToString(Payload,0,Payload.Length,"UTF8")
	Log(Topic & " --- " & Wert)
	If Wert <> "" Then
		Select Case Point
			Case "power"
				If Wert Then ExitApplication
			Case "url" 
				If B4XPages.MainPage.IsInitialized Then
					B4XPages.MainPage.UltimateWebView1.LoadUrl(Wert)
					B4XPages.MainPage.manager.SetString("Url",Wert)
				End If
			Case "screen"
				If Wert Then
					lock.ReleaseKeepAlive
					Sleep(500)
					lock.KeepAlive(True)
					mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/twoway/screen","false".GetBytes("UTF8"))
				Else
					lock.ReleaseKeepAlive
				End If
			Case "screenBrightness"				
				screenBrightness(Wert)
				B4XPages.MainPage.manager.SetString("Brightness",Wert)
			Case "speak" 
				TTS1.Speak(Wert, True)
			Case "vol_music" 
				If ph.GetVolume(ph.VOLUME_MUSIC) <> Wert Then ph.SetVolume(ph.VOLUME_MUSIC,Wert,False)
			Case "vol_notification" 
				If ph.GetVolume(ph.VOLUME_NOTIFICATION) <> Wert Then ph.SetVolume(ph.VOLUME_NOTIFICATION,Wert,False)
			Case "vol_alarm" 
				If ph.GetVolume(ph.VOLUME_ALARM) <> Wert Then ph.SetVolume(ph.VOLUME_ALARM,Wert,False)
			Case "vol_ring" 
				If ph.GetVolume(ph.VOLUME_RING) <> Wert Then ph.SetVolume(ph.VOLUME_RING,Wert,False)
			Case "vol_system" 
				If ph.GetVolume(ph.VOLUME_SYSTEM) <> Wert Then ph.SetVolume(ph.VOLUME_SYSTEM,Wert,False)
			Case "vol_voice_call"
				If ph.GetVolume(ph.VOLUME_VOICE_CALL) <> Wert Then ph.SetVolume(ph.VOLUME_VOICE_CALL,Wert,False)
			Case "fav_1","fav_2","fav_3","fav_4","fav_5","fav_6","fav_7","fav_8","fav_9","fav_10"
				B4XPages.MainPage.manager.SetString(Point,Wert)
				B4XPages.MainPage.addFavorit
		End Select
	End If
End Sub

Sub mqtt_Disconnected
	Log("Disconnected mqtt")
End Sub

Sub ConnectAndReconnect
	Log("ConnectAndReconnect")
	Do While working
		If mqtt.IsInitialized Then mqtt.Close
		Do While mqtt.IsInitialized
			Sleep(100)
		Loop
		If (B4XPages.MainPage.MQTT_Url <> "") Then
			mqtt.Initialize("mqtt", $"tcp://${B4XPages.MainPage.MQTT_Url}:${B4XPages.MainPage.Port}"$, B4XPages.MainPage.MQTT_Name & Rnd(0, 999999999))
			Dim mo As MqttConnectOptions
			mo.Initialize(B4XPages.MainPage.User, B4XPages.MainPage.Password)
			Log("Trying to connect")
			mqtt.Connect2(mo)
			Wait For mqtt_Connected (Success As Boolean)
			If Success Then
				ToastMessageShow("mqtt connected!", True)
				mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/twoway/url",B4XPages.MainPage.Url.GetBytes("UTF8"))
				mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/twoway/power","false".GetBytes("UTF8"))
				mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/twoway/screen","false".GetBytes("UTF8"))
				mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/twoway/speak","".GetBytes("UTF8"))
				mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/twoway/screenBrightness",B4XPages.MainPage.Brightness.GetBytes("UTF8"))
				For i = 1 To 10
					Dim topic As String = "fav_" & i
					mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/twoway/favoriten/" & topic,B4XPages.MainPage.manager.GetString(topic).GetBytes("UTF8"))
				Next
				vol_changed
				mqtt.Subscribe(B4XPages.MainPage.MQTT_Name & "/twoway/#", 1)
				Do While working And mqtt.Connected
					mqtt.Publish2(B4XPages.MainPage.MQTT_Name & "/twoway/ping", Array As Byte(0), 1, False)
					Sleep(5000)			
				Loop
				Log("Disconnected")
			Else
				Log("Error connecting.")
			End If
		End If
		Sleep(5000)
	Loop
End Sub

Sub hg_BatteryChanged (Level As Int, Scale As Int, Plugged As Boolean, Intent As Intent)
	If mqtt.Connected Then
		Dim Lev As String = Level & "%"
		mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/battery/akku", Lev.GetBytes("UTF8"))
		If Plugged Then
			mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/battery/charge", "true".GetBytes("UTF8"))
		Else
			mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/battery/charge", "false".GetBytes("UTF8"))
		End If
	End If
End Sub

Sub BR_OnReceive(Action As String, Extras As Object)
	vol_changed
End Sub

Sub vol_changed
	If mqtt.Connected Then
		Dim vol As String = ph.getvolume(ph.Volume_Music)
		mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/twoway/vol_music",vol.GetBytes("UTF8"))
		vol = ph.getvolume(ph.VOLUME_NOTIFICATION)
		mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/twoway/vol_notification",vol.GetBytes("UTF8"))
		vol = ph.getvolume(ph.VOLUME_ALARM)
		mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/twoway/vol_alarm",vol.GetBytes("UTF8"))
		vol = ph.getvolume(ph.VOLUME_RING)
		mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/twoway/vol_ring",vol.GetBytes("UTF8"))
		vol = ph.getvolume(ph.VOLUME_SYSTEM)
		mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/twoway/vol_system",vol.GetBytes("UTF8"))
		vol = ph.getvolume(ph.VOLUME_VOICE_CALL)
		mqtt.Publish(B4XPages.MainPage.MQTT_Name & "/twoway/vol_voice_call",vol.GetBytes("UTF8"))
	End If
End Sub

Sub screenBrightness( brightnessInt As Int)     '0..255
	Dim J As JavaObject
	J.InitializeContext
	J.RunMethod("setBrightness",Array(J,brightnessInt))
End Sub

#Region Java
#if JAVA
import android.content.Context;
public void setBrightness(Context mContext, int brightnessInt){
   android.provider.Settings.System.putInt(mContext.getContentResolver(), android.provider.Settings.System.SCREEN_BRIGHTNESS_MODE, android.provider.Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL);
   android.provider.Settings.System.putInt(mContext.getContentResolver(), android.provider.Settings.System.SCREEN_BRIGHTNESS, brightnessInt);
}
#End If
#End Region