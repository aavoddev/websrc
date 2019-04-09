{{$sitename := "p1pe.net" -}}
<html>
	<head>
		<!-- Takes influence from BCHS (checkbox css magic), cat-v.org -->
		<title>{{if eq .Title ""}}{{$sitename}}{{else}}{{.Title}}{{end}}</title>
		<style type="text/css" media="screen, handheld">{{Incl "incl/style.css"}}</style>
		<script>
			var ccontainer = 0;
			var center = 0;
			function sidebarEv(e){
				if(e.checked){
					window.name = "sidebar"
				}else{
					window.name = ""
				}
			}
		</script>
		<meta name="viewport" content="width=device-width, initial-scale=1.0" />
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	</head>
	<body>
		<input type="checkbox" name="menucontrol" id="menuctl" value="menuctl"
			onchange="sidebarEv(this)">
		<script>if(window.name == "sidebar"){document.getElementById('menuctl').checked = true;}</script>
		<div id="header">
			<label class="shieldctl noflash" for="menuctl"></label>
			<div id="htable" class="sbtrans sbtransmov">
				<label for="menuctl" id="menubutton" class="noflash sbtrans">
					<div id="menuimg"></div>
				</label>
				<h1 class="title sbtrans sbtransfade"><a href="/">{{$sitename}}</a></h1>
			</div>
		</div>
		<div id="bottom" class="sbtrans sbtransmov">
			<div id="sidebar" class="menu">
				<a href="/" id="home">Home</a>
				<ul>
					{{- block "sdbranch" .Sidebar -}}
						{{- $c := Entries .Base $.Cur -}}
						{{- range $c -}}
							{{- if .Dir -}}
								<li><a href="{{.Lin}}" {{.Attrs}}>
									{{- if .Nod.Antec $.Cur -}}
										» {{else -}}
										› {{end}}{{.Nam}}/</a>
								{{- if .Nod.Antec $.Cur -}}
									<ul>
										{{- $new := sbNewDot .Nod $.Cur -}}
										{{- template "sdbranch" $new -}}
									</ul>
								{{- end -}}
								</li>
							{{- else -}}
								<li><a href="{{.Lin}}" {{.Attrs}}>{{- if nodeequal .Nod $.Cur -}}
									» {{else -}}
									› {{end}}{{.Nam}}</a></li>
							{{- end -}}
						{{- end -}}
					{{- end -}}
				</ul>
				<a href="/sitemap" id="sitemap">{{if Issm .Sidebar.Cur.N}}» {{else}}› {{end}}Site Map</a>
			</div>
			<div id="ccontainer" class="sbtrans sbtransfade">
				<label id="ts" class="shieldctl noflash" for="menuctl"></label>
				<label class="shieldctl noflash" for="menuctl"></label>
				<div id="content">
					{{.Content}}
				</div>
			</div>
		</div>
	</body>
</html>
