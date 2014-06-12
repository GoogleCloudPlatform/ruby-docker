app = ->(env) {
  [200,
   {'Content-Type' => 'text/plain'},
   ['Hello, World!'],
  ]
}

run app
