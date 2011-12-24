#coding: utf-8

class Validator
  def self.validate(coll, req, vld)
    check_constraint = {
      'unique' => (->(f, p) do
        sel = p[0] ? Regexp.new(req[f], true) : req[f]
        if coll.find(f => sel).count > 0
          raise ResponseBadFieldUnique, p[1]
        end
      end),

      'length' => (->(f, p) do
        unless p[0].include?(req[f].size)
          raise ResponseBadFieldLenght, p[1]
        end
      end),

      'format' => (->(f, p) do
        unless p[0] =~ req[f]
          raise ResponseBadFieldFormat, p[1]
        end
      end)
    }

    vld.each_pair do |field, constraints|
      constraints.each_pair do |con_k, con_v|
        check_constraint[con_k].(field, con_v)
      end
    end
  end
end

module VALIDATIONS
  V_USER = {
    'login' => {
      'unique' => [
        true,
        'Login is already in use'
      ],
      'length' => [
        3..20, 
        'Length of login must be in 3..20 characters'
      ],
      'format' => [
        /^\w+$/,
        'Invalid format of login. It must contain only word characters (letter, number, underscore)'
      ]
    },
    'password' => {
      'length' => [
        6..255,
        'Length of password must be in 6..255 characters'
      ]
    }
  }
end

