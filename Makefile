deploy:
	ssh isucon12-qualify-1 " \
		cd /home/isucon; \
		git checkout .; \
		git fetch; \
		git checkout $(BRANCH); \
		git reset --hard origin/$(BRANCH)"

build:
	ssh isucon12-qualify-1 "sudo systemctl restart isuports.service"

mysql-deploy:
	ssh isucon12-qualify-1 "sudo dd of=/etc/mysql/mysql.conf.d/mysqld.cnf" < ./etc/mysql/mysql.conf.d/mysqld.cnf

mysql-rotate:
	ssh isucon12-qualify-1 "sudo rm -f /var/log/mysql/mysql-slow.log"

mysql-restart:
	ssh isucon12-qualify-1 "sudo systemctl restart mysql.service"

nginx-rotate:
	ssh isucon12-qualify-1 "sudo rm -f /var/log/nginx/access.log"

nginx-reload:
	ssh isucon12-qualify-1 "sudo systemctl reload nginx.service"

nginx-restart:
	ssh isucon12-qualify-1 "sudo systemctl restart nginx.service"

bench-run:
	ssh isucon12-qualify-1 " \
		cd /home/isucon/benchmarker; \
		./bin/benchmarker -target localhost:443 -tls"

pt-query-digest:
	ssh isucon12-qualify-1 "sudo pt-query-digest --limit 10 /var/log/mysql/mysql-slow.log"

ALPSORT=sum
# /api/courses/[0-9A-Z]{26}/classes/[0-9A-Z]{26}/assignments/export
# /api/courses/[0-9A-Z]{26}/classes/[0-9A-Z]{26}/assignments/scores
# /api/courses/[0-9A-Z]{26}/classes/[0-9A-Z]{26}/assignments
# /api/courses/[0-9A-Z]{26}/classes
# /api/courses/[0-9A-Z]{26}/status
# /api/courses/[0-9A-Z]{26}
# /api/courses?.*
# /api/announcements/[0-9A-Z]{26}
# /api/announcements?.*
ALPM="/api/courses/[0-9A-Z]{26}/classes/[0-9A-Z]{26}/assignments/export,/api/courses/[0-9A-Z]{26}/classes/[0-9A-Z]{26}/assignments/scores,/api/courses/[0-9A-Z]{26}/classes/[0-9A-Z]{26}/assignments,/api/announcements/[0-9A-Z]{26},/api/courses/[0-9A-Z]{26}/status,/api/courses/[0-9A-Z]{26}/classes,/api/courses/[0-9A-Z]{26},/api/courses?.*,/api/announcements?.*"
OUTFORMAT=count,method,uri,min,max,sum,avg,p99

alp:
	ssh isucon12-qualify-1 "sudo alp ltsv --file=/var/log/nginx/access.log --nosave-pos --pos /tmp/alp.pos --sort $(ALPSORT) --reverse -o $(OUTFORMAT) -m $(ALPM) -q"

.PHONY: pprof
pprof:
	ssh isucon12-qualify-1 "/home/isucon/local/go/bin/go tool pprof -seconds=75 webapp/go/isucholar http://localhost:6060/debug/pprof/profile"

pprof-kill:
	ssh isucon12-qualify-1 "pgrep -f 'pprof' | xargs kill;"

pprof-show:
	$(eval latest := $(shell ssh isucon12-qualify-1 "ls -rt ~/pprof/ | tail -n 1"))
	scp isucon12-qualify-1:~/pprof/$(latest) ./pprof
	go tool pprof -http=":1080" ./pprof/$(latest)
