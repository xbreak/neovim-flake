
(expression_statement
  (call_expression
    function:
      (identifier) @log4cplus.macro
      (#lua-match? @log4cplus.macro "^LOG4CPLUS_[A-Z_]+")
  )
  @log4cplus.stmt (#set! "priority" 105))
