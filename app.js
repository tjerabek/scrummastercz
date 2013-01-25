
/**
 * Module dependencies.
 */

var express = require('express')
  , routes = require('./routes')
  , user = require('./routes/user')
  , http = require('http')
  , path = require('path')
  , mongoose = require('mongoose')
  , passport = require('passport')
  , TwitterStrategy = require('passport-twitter').Strategy;

passport.use(new TwitterStrategy({
    consumerKey: "<<Your key>>",
    consumerSecret: "<<Your secret>>",
    callbackURL: "http://www.scrummaster.cz:80/auth/twitter/callback"
},
  function (token, tokenSecret, profile, done) {
      
      return done(null, { email: profile.id, name: profile.username });
  }
));

var app = express();

app.configure(function(){
  app.set('port', process.env.PORT || 80);
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.favicon());
  app.use(express.logger('dev'));
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(express.cookieParser('your secret here'));
  app.use(express.session());
  app.use(passport.initialize());
  app.use(passport.session());
  app.use(app.router);
  app.use(require('stylus').middleware(__dirname + '/public'));
  app.use(express.static(path.join(__dirname, 'public')));
});

app.configure('development', function(){
  app.use(express.errorHandler());
});

app.get('/', routes.index);
app.post('/create-project', routes.createProject);
app.post('/:project/create-project', routes.createProject);
app.get('/:project/', routes.index);
app.get('/:project/:tag/todo.json', routes.todo);
app.get('/:project/todo.json', routes.todo);
app.get('/:project/inprogress.json', routes.inprogress);
app.get('/:project/:tag/inprogress.json', routes.inprogress);
app.get('/:project/done.json', routes.done);
app.get('/:project/:tag/done.json', routes.done);
app.get('/todo.json', routes.todo);
app.get('/inprogress.json', routes.inprogress);
app.get('/done.json', routes.done);
app.get('/projects.json', routes.projects);
app.get('/:project/projects.json', routes.projects);


app.get('/info.json', routes.info);
app.get('/:project/info.json', routes.info);

app.post('/:project/save', routes.save);
app.post('/:project/makeInProgress', routes.makeInProgress);
app.post('/:project/makeDone', routes.makeDone);
app.post('/:project/makeTodo', routes.makeTodo);
app.post('/:project/remove', routes.remove);
app.post('/:project/update', routes.update);
app.get('/dashboard', ensureAuthenticated, routes.dashboard);

passport.serializeUser(function (user, done) {
    done(null, user);
});

passport.deserializeUser(function (obj, done) {
    done(null, obj);
});

http.createServer(app).listen(app.get('port'), function(){
  console.log("Express server listening on port " + app.get('port'));
});

app.get('/auth/twitter',
  passport.authenticate('twitter'));

app.get('/auth/twitter/callback',
  passport.authenticate('twitter', { failureRedirect: '/' }),
  function (req, res) {
      res.redirect('/');
  });


function ensureAuthenticated(req, res, next) {
    if (req.isAuthenticated()) { return next(); }
    res.redirect('/')
}