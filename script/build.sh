APP_ROOT="$(dirname "$(dirname "$(readlink -fm "$0")")")"

docker build $APP_ROOT
