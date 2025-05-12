%code requires {
    #include <string>
    #include <vector>
    #include <windows.h>
    #include <map>
    #include <memory>

    

    enum ActionType { PRINT_VAR, DO_WHILE };
    enum OperatorType { INCREMENT, DECREMENT };
    enum CompareType { LESS_THAN, GREATER_THAN };

    struct Action {
        ActionType type;
        std::vector<Action> nested;
        std::string var_name;
        OperatorType op_type;
        std::string cond_var;
        OperatorType cond_op_type;
        int cond_limit;
        CompareType cmp_type;
    };

    struct ConditionInfo {
        OperatorType op_type;
        std::string var_name;
        int limit;
        CompareType cmp_type;
    };

    extern void init_variable(const std::string& name);

    extern std::map<std::string, int> variables;
    extern FILE* yyin;
    void execute_action(const Action& action, int depth = 0);
}

%{
#include <cstdlib>
#include <utility>
#include <map>
#include <iostream>
#include <string>

int yylex();
void yyerror(const char* s);

std::map<std::string, int> variables;
%}

%union {
    int ival;
    std::string* str;
    std::vector<Action>* actions;
    std::pair<OperatorType, std::string>* op_var;
    ConditionInfo* cond_info;
}

%token DO WHILE PRINT
%token INC DEC
%token LT GT
%token SEMICOLON LBRACE RBRACE LPAREN RPAREN
%token <ival> NUMBER
%token <str> VAR

%type <op_var> inc_dec_op
%type <cond_info> condition
%type <actions> block action_list action print_stmt dws_block

%%

program:
    /* пусто */
    | program DWS
;

DWS:
    DO block WHILE LPAREN condition RPAREN SEMICOLON {
        auto block_actions = *$2;
        auto* cond = $5;
        
        int max_iter = 100, iter = 0;
        bool result;

        do {
            if (++iter > max_iter) {
                std::cerr << "[ОШИБКА] Превышен лимит итераций\n";
                exit(1);
            }

            std::cout << "[Итерация " << iter << "]\n";
            
            for (const auto& act : block_actions) {
                execute_action(act, 1);
            }

            int before = variables[cond->var_name];
            int after;
            if (cond->op_type == INCREMENT) {
                after = ++variables[cond->var_name];
            } else {
                after = --variables[cond->var_name];
            }
            
            if (cond->cmp_type == LESS_THAN) {
                result = after < cond->limit;
            } else {
                result = after > cond->limit;
            }

            std::cout << "[Условие] проверка: " 
                      << (cond->op_type == INCREMENT ? "++" : "--") 
                      << cond->var_name << "[" << before << "] "
                      << (cond->cmp_type == LESS_THAN ? "<" : ">") << " " << cond->limit
                      << " → " << (result ? "истинно" : "ложно") << "\n";

        } while (result);
        
        delete $2;
        delete cond;
    }
;

block:
    LBRACE action_list RBRACE { $$ = $2; }
;

action_list:
    action_list action {
        $1->insert($1->end(), $2->begin(), $2->end());
        delete $2;
        $$ = $1;
    }
    | action { $$ = $1; }
;

action:
    print_stmt
    | dws_block
;

print_stmt:
    PRINT LPAREN inc_dec_op RPAREN SEMICOLON {
        auto list = new std::vector<Action>();
        Action act;
        act.type = PRINT_VAR;
        act.var_name = $3->second;
        act.op_type = $3->first;
        list->push_back(act);
        delete $3;
        $$ = list;
    }
;

dws_block:
    DO block WHILE LPAREN condition RPAREN SEMICOLON {
        auto list = new std::vector<Action>();
        Action nested;
        nested.type = DO_WHILE;
        nested.nested = *$2;
        auto* cond = $5;
        nested.cond_var = cond->var_name;
        nested.cond_op_type = cond->op_type;
        nested.cond_limit = cond->limit;
        nested.cmp_type = cond->cmp_type;
        delete $2;
        delete cond;
        list->push_back(nested);
        $$ = list;
    }
;

inc_dec_op:
    INC VAR { 
        init_variable(*$2);
        $$ = new std::pair<OperatorType, std::string>(INCREMENT, *$2); 
        delete $2; 
    }
    | DEC VAR { 
        init_variable(*$2);
        $$ = new std::pair<OperatorType, std::string>(DECREMENT, *$2); 
        delete $2; 
    }
;

condition:
    inc_dec_op LT NUMBER {
        $$ = new ConditionInfo{$1->first, $1->second, $3, LESS_THAN};
        delete $1;
    }
    | inc_dec_op GT NUMBER {
        $$ = new ConditionInfo{$1->first, $1->second, $3, GREATER_THAN};
        delete $1;
    }
;

%%

void init_variable(const std::string& name) {
    if (variables.find(name) == variables.end()) {
        variables[name] = 0;
        std::cout << "[Инициализация] Переменная " << name << " = 0\n";
    }
}

void execute_action(const Action& action, int depth) {
    if (action.type == PRINT_VAR) {
        init_variable(action.var_name);
    }
    else if (action.type == DO_WHILE) {
        init_variable(action.cond_var);
    }

    std::string indent(depth * 2, ' ');
    
    switch (action.type) {
        case PRINT_VAR: {
            int& var = variables[action.var_name];
            int before = var;
            if (action.op_type == INCREMENT) {
                ++var;
            } else {
                --var;
            }
            std::cout << indent << action.var_name << " = " << var << " (было " << before << ")\n";
            break;
        }
        case DO_WHILE: {
            int iter = 0;
            bool result;
            
            do {
                if (++iter > 100) {
                    std::cerr << indent << "[ОШИБКА] Превышен лимит итераций цикла\n";
                    exit(1);
                }
                
                std::cout << indent << "[Итерация " << iter << "]\n";
                
                for (const auto& nested_action : action.nested) {
                    execute_action(nested_action, depth + 1);
                }
                
                int before = variables[action.cond_var];
                int after;
                if (action.cond_op_type == INCREMENT) {
                    after = ++variables[action.cond_var];
                } else {
                    after = --variables[action.cond_var];
                }
                
                if (action.cmp_type == LESS_THAN) {
                    result = after < action.cond_limit;
                } else {
                    result = after > action.cond_limit;
                }
                
                std::cout << indent << "[Условие] проверка: " 
                          << (action.cond_op_type == INCREMENT ? "++" : "--") 
                          << action.cond_var << "[" << before << "] "
                          << (action.cmp_type == LESS_THAN ? "<" : ">") << " " << action.cond_limit
                          << " → " << (result ? "истинно" : "ложно") << "\n";
            } while (result);
            break;
        }
    }
}

void yyerror(const char* s) {
    std::cerr << "Ошибка: " << s << "\n";
}

int main() {
    SetConsoleOutputCP(CP_UTF8);
    yyin = fopen("input.txt", "r");
    if (!yyin) {
        std::cerr << "Не удалось открыть input.txt" << std::endl;
        return 1;
    }

    std::cout << "=== Выполнение do-while ===" << std::endl;
    yyparse();
    fclose(yyin);

    std::cout << "\n=== Итоговые значения переменных ===" << std::endl;
    for (const auto& [name, value] : variables) {
        std::cout << name << " = " << value << std::endl;
    }
    
    return 0; 
}
