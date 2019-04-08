<h1>{{.Title}}/</h1>
{{- $c := Entries .Sidebar.Base .Sidebar.Base -}}
{{- range $c -}}
	{{- if .Dir -}}
		<li><a href="{{.Lin}}">{{.Nam}}/</a></li>
	{{- else -}}
		<li><a href="{{.Lin}}">{{.Nam}}</a></li>
	{{- end -}}
{{- end -}}
