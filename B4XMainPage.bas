B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView	
	Private cs As CSBuilder
	Private Keyboard As IME
	Private Drawer As B4XDrawer
	Private ListView1 As ListView
	Private ListView2 As ListView
	Private EditText1 As EditText
	Private Panel1 As Panel
	Private Button1 As Button
	Private screen As PreferenceScreen
	Public manager As PreferenceManager
	Public UltimateWebView1 As UltimateWebView
	
	Public MQTT_Url,Port,User,Password,Url,MQTT_Name,Brightness As String
End Sub

Public Sub Initialize
	B4XPages.GetManager.LogEvents = True
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Drawer.Initialize(Me, "Drawer", Root, 280dip)
	Drawer.CenterPanel.LoadLayout("MainPage")
	Drawer.LeftPanel.LoadLayout("1")
	Drawer.RightPanel.LoadLayout("2")
	Drawer.RightPanelEnabled = True
	CreatePreferenceScreen
	If manager.GetAll.Size = 0 Then SetDefaults
	Url = manager.GetString("Url")
	MQTT_Url = manager.GetString("MQTT_Url")
	Port = manager.GetString("Port")
	MQTT_Name = manager.GetString("MQTT_Name")
	Password = manager.GetString("Password")
	User = manager.GetString("User")
	Brightness = manager.GetString("Brightness")
	addDefaults
End Sub

Private Sub B4XPage_CloseRequest As ResumableSub
	If Drawer.LeftOpen Then
		Drawer.LeftOpen = False
		Return False
	End If
	Return True	
End Sub

Sub B4XPage_Appear
	If Not(Tracker.mqtt.Connected) Then
		Url = manager.GetString("Url")
		MQTT_Url = manager.GetString("MQTT_Url")
		Port = manager.GetString("Port")
		MQTT_Name = manager.GetString("MQTT_Name")
		Password = manager.GetString("Password")
		User = manager.GetString("User")
		Brightness = manager.GetString("Brightness")
	End If	
	UltimateWebView1.LoadUrl(Url)
	addFavorit
End Sub

Sub B4XPage_Disappear

End Sub

Sub ListView1_ItemClick (Position As Int, Value As Object)
	Drawer.LeftOpen = False
	Select Case Position
		Case 1
			Panel1.Visible = True
		Case 2
			If UltimateWebView1.CanGoBack Then UltimateWebView1.GoBack
		Case 3
			If UltimateWebView1.CanGoForward Then UltimateWebView1.GoForward
		Case 4
			manager.SetString("Url",Url)
			addFavorit
		Case 5
			StartActivity(screen.CreateIntent)
		Case 6
			ExitApplication
	End Select
End Sub

Sub ListView2_ItemClick (Position As Int, Value As Object)
	Drawer.RightOpen = False		
	Dim favo As String = "fav_" & Position
	UltimateWebView1.LoadUrl(manager.GetString(favo))
End Sub

Private Sub ListView2_ItemLongClick (Position As Int, Value As Object)
	Drawer.LeftOpen = False
	Dim favo As String = "fav_" & Position
	manager.SetString(favo,Url)
	addFavorit
End Sub

Sub Button1_Click()
	Keyboard.Initialize("")
	Keyboard.HideKeyboard
	Log(EditText1.Text)
	Url = EditText1.Text
	UltimateWebView1.LoadUrl(Url)
	Panel1.Visible = False
End Sub

Private Sub UltimateWebView1_PageFinished (WebUrl As String)
	Url = WebUrl
End Sub

#Region --------------------Funktionen------------------
Public Sub addFavorit
	ListView2.Clear
	ListView2.SingleLineLayout.Label.TextSize = 16
	ListView2.AddTwoLines( cs.Initialize.Size(32).Alignment("ALIGN_CENTER").PopAll.Append("Favoriten     "),cs.Initialize.Size(32).Alignment("ALIGN_CENTER").PopAll.Append("______________     "))
	For i = 1 To 10
		Dim index As String = "fav_" & i
		ListView2.AddSingleLine( cs.Initialize.Typeface(Typeface.MATERIALICONS).Size(22).VerticalAlign(3dip).Append(Chr(0xE83A)).PopAll.Append(manager.GetString(index)))
	Next
End Sub

Sub addDefaults
	ListView1.Clear
	ListView1.SingleLineLayout.Label.TextSize = 16
	ListView1.AddTwoLines( cs.Initialize.Size(32).Alignment("ALIGN_CENTER").PopAll.Append("ioBrowser     "),cs.Initialize.Size(32).Alignment("ALIGN_CENTER").PopAll.Append("______________     "))
	ListView1.AddSingleLine( cs.Initialize.Typeface(Typeface.MATERIALICONS).Size(22).VerticalAlign(3dip).Append(Chr(0xE069)).PopAll.Append("  Url") )
	ListView1.AddSingleLine( cs.Initialize.Typeface(Typeface.FONTAWESOME).Size(22).VerticalAlign(3dip).Append(Chr(0xF0A5)).PopAll.Append("  GoBack") )
	ListView1.AddSingleLine( cs.Initialize.Typeface(Typeface.FONTAWESOME).Size(22).VerticalAlign(3dip).Append(Chr(0xF0A4)).PopAll.Append("  GoForward") )
	ListView1.AddSingleLine( cs.Initialize.Typeface(Typeface.MATERIALICONS).Size(22).VerticalAlign(3dip).Append(Chr(0xE250)).PopAll.Append("  Set as StartPage") )
	ListView1.AddSingleLine( cs.Initialize.Typeface(Typeface.MATERIALICONS).Size(22).VerticalAlign(3dip).Append(Chr(0xE8B8)).PopAll.Append("  Config") )
	ListView1.AddSingleLine( cs.Initialize.Typeface(Typeface.MATERIALICONS).Size(22).VerticalAlign(3dip).Append(Chr(0xE8AC)).PopAll.Append("  Exit") )
	UltimateWebView1.SetWebViewClient
	UltimateWebView1.SetWebChromeClient
	UltimateWebView1.Settings.JavaScriptEnabled=True
	UltimateWebView1.Settings.AllowContentAccess=True
	UltimateWebView1.Settings.AllowFileAccess=True
	UltimateWebView1.Settings.AppCacheEnabled=True
	UltimateWebView1.Settings.JavaScriptCanOpenWindowsAutomatically=True
	UltimateWebView1.Settings.DisplayZoomControls=False
	UltimateWebView1.Settings.DomStorageEnabled=True
End Sub

Sub SetDefaults
	'defaults are only set on the first run.
	manager.SetString("MQTT_Url","192.168.0.100")
	manager.SetString("Port","1883")
	manager.SetString("MQTT_Name","tablet")
	manager.SetString("User", "")
	manager.SetString("Passwort","")
	manager.SetString("Brightness","255")
End Sub

Sub CreatePreferenceScreen
	screen.Initialize("Settings", "")
	Dim cat1, cat2, cat3 As PreferenceCategory
	
	cat1.Initialize("MQTT")
	cat1.AddEditText("MQTT_Url","Url","Url", MQTT_Url)
	cat1.AddEditText("Port","Port","Port", Port)
	cat1.AddEditText("MQTT_Name","Client","Name", MQTT_Name)
	cat1.AddEditText("User","User","Name", User)
	cat1.AddEditText("Password","Password","Password", Password)
	cat2.Initialize("StartPage")
	cat2.AddEditText("Url","Url","Url", Url)
	cat2.AddEditText("Brightness","Brightness","Brightness",Brightness)
	cat3.Initialize("Favoriten")
	cat3.AddEditText("fav_1","Favorit 1","Url", "")
	cat3.AddEditText("fav_2","Favorit 2","Url", "")
	cat3.AddEditText("fav_3","Favorit 3","Url", "")
	cat3.AddEditText("fav_4","Favorit 4","Url", "")
	cat3.AddEditText("fav_5","Favorit 5","Url", "")
	cat3.AddEditText("fav_6","Favorit 6","Url", "")
	cat3.AddEditText("fav_7","Favorit 7","Url", "")
	cat3.AddEditText("fav_8","Favorit 8","Url", "")
	cat3.AddEditText("fav_9","Favorit 9","Url", "")
	cat3.AddEditText("fav_10","Favorit 10","Url", "")
	
	screen.AddPreferenceCategory(cat1)
	screen.AddPreferenceCategory(cat2)
	screen.AddPreferenceCategory(cat3)
End Sub

#End Region