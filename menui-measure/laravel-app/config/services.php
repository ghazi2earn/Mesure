<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Services de tiers
    |--------------------------------------------------------------------------
    |
    | Ce fichier contient les configurations pour les services tiers utilisés
    | par l'application.
    |
    */

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
        'scheme' => 'https',
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'ai' => [
        'url' => env('AI_SERVICE_URL', 'http://ai-service:8000'),
        'timeout' => env('AI_SERVICE_TIMEOUT', 60),
    ],

    'ovh' => [
        'access_key_id' => env('OVH_ACCESS_KEY_ID'),
        'secret_access_key' => env('OVH_SECRET_ACCESS_KEY'),
        'default_region' => env('OVH_DEFAULT_REGION', 'BHS'),
        'bucket' => env('OVH_BUCKET'),
        'endpoint' => env('OVH_ENDPOINT', 'https://s3.bhs.io.cloud.ovh.net'),
    ],

    'twilio' => [
        'sid' => env('TWILIO_ACCOUNT_SID'),
        'token' => env('TWILIO_AUTH_TOKEN'),
        'whatsapp_from' => env('TWILIO_WHATSAPP_FROM'),
    ],

];