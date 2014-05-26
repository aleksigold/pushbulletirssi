use strict;
use warnings;

#####################################################################
# This script sends hilights and private messages to PushBullet,    #
# modified from boxcarirssi.pl                                      #
#                                                                   #
# Original script by Caesar 'sniker' Ahlenhed                       #
#                                                                   #
# /set pushbullet_api APIKEY                                        #
#                                                                   #
#####################################################################

use Irssi;
use Irssi::Irc;
use vars qw($VERSION %IRSSI);
use HTTP::Response;
use WWW::Curl::Easy;
use JSON;
use URI::Escape;

$VERSION = "0.1";

%IRSSI = (
    authors     => "Aleksi 'tehspede' Gold",
    contact     => "goldaleksi\@gmail.com",
    name        => "pushbullet",
    description => "Sends notifcations when away",
    license     => "GPLv2",
    url         => "http://google.com",
    changed     => "Mon May 26 16:22:16 EEST 2014",
);

# Configuration settings and default values.
Irssi::settings_add_bool("pushbullet", "pushbullet_general_hilight", 1);
Irssi::settings_add_str("pushbullet", "pushbullet_api", "api");
my $curl = WWW::Curl::Easy->new;

sub send_noti {
    my $params = shift;
    my %options = %$params;;
    my $options_str = "type=note";

    foreach my $key (keys %options) {
        my $val = $options{$key};
        $options_str .= "\&$key=$val";
    }

    $curl->setopt(CURLOPT_HEADER, 1);
    $curl->setopt(CURLOPT_URL, "https:\/\/api.pushbullet.com\/v2\/pushes");
    $curl->setopt(CURLOPT_USERPWD, Irssi::settings_get_str("pushbullet_api") . ":");
    $curl->setopt(CURLOPT_POST, 1);
    $curl->setopt(CURLOPT_POSTFIELDS, $options_str);
    $curl->setopt(CURLOPT_POSTFIELDSIZE, length($options_str));

    my $response;
    $curl->setopt(CURLOPT_WRITEDATA, \$response);
    my $retcode = $curl->perform;

    if ($retcode != 0) {
        print("Issue pushing bullet");
        return 0;
    }
    return 1;
}

sub pubmsg {
    my ($server, $data, $nick) = @_;

    if($server->{usermode_away} == 1 && $data =~ /$server->{nick}/i){
        my %options = ("title" => "IRSSI - <" . $nick .'>: ' . $data, "body" => "<" . $nick . '>: ' . $data);
        send_noti(\%options)
    }
}

sub privmsg {
    my ($server, $data, $nick) = @_;
    if($server->{usermode_away} == 1){
        my %options = ("title" => "IRSSI - <" . $nick .'>: ' . $data, "body" => "<" . $nick . '>: ' . $data);
        send_noti(\%options)
    }
}

sub genhilight {
    my($dest, $text, $stripped) = @_;
    my $server = $dest->{server};

    if($dest->{level} & MSGLEVEL_HILIGHT) {
        if($server->{usermode_away} == 1){
            if(Irssi::settings_get_bool("pushbullet_general_hilight")){
                my %options = ("title" => "IRSSI - Hilighted", "body" => $stripped);
                send_noti(\%options)
            }
        }
    }
}

Irssi::signal_add_last('message public', 'pubmsg');
Irssi::signal_add_last('message private', 'privmsg');
Irssi::signal_add_last('print text', 'genhilight');
