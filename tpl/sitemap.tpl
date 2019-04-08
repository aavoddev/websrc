<h1>{{.Title}}</h1>

<div class="menu">
	<ul>
		{{- block "sitemap" .Sidebar -}}
			{{- $c := Entries .Base $.Cur -}}
			{{- range $c -}}
				{{- if .Dir -}}
					<li><a href="{{.Lin}}" {{.Attrs}}>› {{.Nam}}/</a>
						<ul>
							{{- $new := sbNewDot .Nod $.Cur -}}
							{{- template "sitemap" $new -}}
						</ul>
					</li>
				{{- else -}}
					<li><a href="{{.Lin}}" {{.Attrs}}>› {{.Nam}}</a></li>
				{{- end -}}
			{{- end -}}
		{{- end -}}
	</ul>
</div>
