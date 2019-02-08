#!/bin/bash
# --------------------------------------------------------
# Licenciatura em Engenharia Informática
# Sistemas Operativos | Trabalho Prático 1
# Ano letivo 2018/2019 - 1º Semestre - Turma P2
# 
# Alunos:
# 88808 | João Miguel Nunes de Medeiros e Vasconcelos 
# 88886 | Tiago Carvalho Mendes
# -------------------------------------------------------

##############################################################################################
# 1 - TRATAMENTO DA LINHA DE COMANDOS
##############################################################################################

# 1.1 - Declarar e inicializar diversas variáveis globais
# Estas variáveis irão guardar o valor de verdade da presença das opções válidas passadas na linha de comandos
IFS=$(echo -en "\n\b")
opt_a=false             # Opção -a
opt_d=false             # Opção -d
opt_l=false             # Opção -l
opt_L=false             # Opção -L
opt_n=false             # Opção -n
opt_r=false             # Opção -r
opt_e=false             # Opção -e

opt_d_arg=false         # Argumento da opção -d
opt_l_arg=false         # Argumento da opção -l
opt_L_arg=false         # Argumento da opção -L
opt_n_arg=false         # Argumento da opção -n
opt_e_arg=false         # Argumento da opção -e
essential_files=()      # Array que irá armazenar os ficheiros essenciais a serem ignorados pelo script

# 1.2 - Verificar a presença ou omissão de todas as opções válidas, bem como dos respetivos argumentos

# 1.2.1 - Funções auxiliares

# 1.2.1.1 - Função usage() 
# Função chamada sempre que a linha de comandos contém parâmetros inválidos, interrompendo o script.
# Esta função adverte o utilizador para a correta utilização do script.
function usage(){
    echo
    echo "usage: nespace.sh [-a] [-d date_value] [-e file_list] [-l int_value or -L int_value] [-n regular_expression] [-r] dir1 [dir2 ...]"
    echo "       -a: sort alphabetically"
    echo "       -d date_value: maximum file date access"
    echo "       -e file_list: list of files to be ignored by the script "
    echo "       -l int_value: number of the biggest files to be consider in each directory"
    echo "       -L int_value: number of the biggest files to be consider in all directories"
    echo "          *Note: -l and -L can not be used at the same time"
    echo "       -n regular_expression: only files that matches this regular expression can be consider"
    echo "       -r: sort in reverse order"
    echo "       dir1, dir2, etc.: directories to be consider"
    echo "          *Note: dir1 is required and all directories must be in the end of the command-line"
    exit 1
}

# 1.2.1.2 - Função verifyArguments()
# Verifica se um argumento de uma opção é ou não também ele uma opção.  
function verifyArguments(){
    if [[ $1 = -* ]]; then  
        echo "ERROR: option -$opt requires an argument, not an option."
        ((OPTIND--))
        usage
    fi
}

# 1.2.1.3 - Função verifyArguments2()
# Verifica se uma opção já apareceu duas vezes na linha de comandos
function verifyArguments2(){
    if ( $1 ); then
        echo "ERROR: option -$opt already used"
        usage
    fi
}

# 1.2.2 - Parsing das opções usando o comando getopts
while getopts ":ad:l:L:n:e:r" opt; 
do
   case $opt in
        a)
            verifyArguments2 $opt_a
            opt_a=true
            ;;
        d)  
            verifyArguments2 $opt_d
            opt_d_arg=$OPTARG
            verifyArguments "$opt_d_arg"
            opt_d=true
            ;;
        l)  
            verifyArguments2 $opt_l
            opt_l_arg=$OPTARG
            verifyArguments "$opt_l_arg"
            opt_l=true
            ;;
        L)
            verifyArguments2 $opt_L
            opt_L_arg=$OPTARG
            verifyArguments "$opt_L_arg"
            opt_L=true
            ;;
        n)  
            verifyArguments2 $opt_n
            opt_n_arg=$OPTARG
            verifyArguments "$opt_n_arg"
            opt_n=true
            ;;
        r)
            verifyArguments2 $opt_r
            opt_r=true
            ;;
        e)
            verifyArguments2 $opt_e
            opt_e_arg=$OPTARG
            verifyArguments "$opt_e_arg"
            opt_e=true
            ;;
        :)
            echo "ERROR: option -$OPTARG requires an argument"
            usage
            ;;
        ?)  
            echo "ERROR: option unknown"
            usage
            ;;
   esac
done
# Com o comando "shift $(($OPTIND - 1))"", a variável $@ irá conter todos os argumentos não processados 
# pelo comando 'getopts' (neste script, esses argumentos serão os nomes das diretorias passadas na linha de comandos).
shift $(($OPTIND - 1)) 

# 1.3 - Verificar a validade das diferentes opções e dos seus respetivos argumentos

# 1.3.1 - Verificar a introdução de diretorias no final da linha de comandos
if [[ $# == 0 ]]; then
    echo "ERROR: no directories have been passed"
    usage
fi

# 1.3.2 - Verificar a existência de alguma diretoria que comece com o carater '-'
# No sistema operativo Linux, apenas os nomes de diretorias começados com o carater '/' são inválidos,
# no entanto decidimos restringir também os nomes começados em '-', para não confundir nomes de diretorias
# com opções válidas.
for i in $@
do
    if [[ $i = -* ]]; then
        echo "ERROR: directories name can not start with '-'"
        usage
    fi
done

# 1.3.3 - Verificar o argumento da opção -l, que tem de ser um inteiro
if ( $opt_l ); then
    if ! [[ $opt_l_arg =~ ^[0-9]+$ ]] ; then
        echo "ERROR: the argument of -l option is not an integer value"
        usage
    fi
fi

# 1.3.4 - Verificar o argumento da opção -L, que tem de ser um inteiro
if ( $opt_L ); then
    if ! [[ $opt_L_arg =~ ^[0-9]+$ ]] ; then
        echo "ERROR: the argument of -L option is not an integer value"
        usage
    fi
fi

# 1.3.5 - Verificar a coexistência das opções -l e -L
if ( $opt_l && $opt_L ); then
    echo "ERROR: options -l and -L can not be passed together"
    usage
fi

# 1.3.6 - Verificar se os nomes das diretorias passados na linha de comandos são realmente diretorias 
for i in $@
do
    if [ ! -d $i ]; then
        echo "ERROR: $i is not a directory"
        usage
    fi
done

# 1.3.7 - Verificar a data passada na linha de comandos
if ( $opt_d ); then
    date_flag=$(date -d $opt_d_arg)
    if [ $? -eq 0 ]; then
        opt_d_arg=$(date -d $opt_d_arg "+%Y%m%d%H%M")
    else
        echo "ERROR: the argument of -d option is an invalid date"
        usage
    fi
fi

# 1.3.8 - Verificar se a lista com nomes de ficheiros passada na linha de comandos é um ficheiro
if ( $opt_e ); then
    if [ -f $opt_e_arg  ]; then
        # Ler todas as linhas do ficheiro e armazená-las num array
        for line in $(<$opt_e_arg); do essential_files+=("${line}"); done
    else
        echo "ERROR: the argument of -e option is an invalid file"
        usage
    fi
fi

##############################################################################################
# 2 - PROCESSAMENTO PRINCIPAL DO TAMANHO DAS DIRETORIAS E FICHEIROS PRETENDIDOS
##############################################################################################

# 2.1 - Função recursiva showFiles() 
# Esta função percorre todos os ficheiros e sub-diretorias de uma diretoria passada na linha de comandos.
function showFiles() {

    # Variável que irá guardar o tamanho de uma diretoria
    total_space=0;
    
    # Ciclo for para percorrer todos os ficheiros e sub-diretorias de uma diretoria 
    for file in "$1"/* 
    do
        # Verificar se um ficheiro ou uma diretoria têm permissões de leitura
        if ! [ -r $file ] ; then
            if [ -d $file ]; then
                path_array+=("${file}")
                size_array+=(0) 
            fi
            continue
        fi
        # Se $file for um ficheiro
        if [  -f "${file}" ]; then
            # Verificar se estamos na presença de um ficheiro essencial
            if ( $opt_e ); then
                ignore_file=false
                for f in ${essential_files[@]}
                do
                    if [[ $file =~ "$f" ]]; then
                        ignore_file=true 
                    fi
                done
                if ( $ignore_file ); then 
                   continue 
                fi
            fi

            # Obter o espaço ocupado por um ficheiro
            space=$(ls -l ${file} 2>/dev/null | awk '{print $5}')
            
            # Obter a última data de acesso ao ficheiro no formato AnoMêsDiaHoraMinuto
            file_date=$(stat $file | tail -4 | head -1 | awk '{print $2, $3}')
            file_date=$(date -d $file_date "+%Y%m%d%H%M")
            
            # Verificar se os ficheiros satisfazem determinadas condições
            if [ $opt_l = false ]; then
                # Opções -n e -d passadas na liha de comandos
                if [ $opt_n = true -a $opt_d = true ]; then
                    if [[ $file_date -le $opt_d_arg && $file =~ "$opt_n_arg" ]]; then
                        total_space=$((total_space + space));
                        file_dictionary[$file]=$space
                    fi
                # Opção -n passada na linha de comandos
                elif [ $opt_n = true ]; then
                    if [[ $file =~ "$opt_n_arg" ]]; then
                        total_space=$((total_space + space));
                        file_dictionary[$file]=$space
                    fi
                # Opção -d passada na linha de comandos
                elif [ $opt_d = true ]; then
                    if [ $file_date -le $opt_d_arg ]; then
                        total_space=$((total_space + space));
                        file_dictionary[$file]=$space
                    fi 
                # Opções -n e -d ausentes na liha de comandos
                else
                    total_space=$((total_space + space));
                    file_dictionary[$file]=$space
                fi
            fi

        # Se $file for uma diretoria
        elif [ -d "${file}" ];then
            # Ignorar diretorias vazias
            if [ "$(ls -A $file)" 2>/dev/null ]; then
                # Adicionar a diretoria e o tamanho correspondente dois arrays distintos
                path_array+=("${file}")
                size_array+=("${total_space}") 

                # Chamada recursiva da função showFiles(), passando a sub-diretoria como argumento  
                showFiles "${file}"
            fi
        fi
    done
}

# 2.2 - Função print() 
# Esta função imprime o tamanho de cada sub-diretoria das diretorias passadas na linha de comandos
function print() {

    # Considerar apenas os $opt_l_arg maiores ficheiros de cada diretoria 
    if [ $opt_l = true ]; then
        # Ciclo que percorre todas as diretorias armazenadas no main_dictionary
        for i in "${!main_dictionary[@]}"
        do  
            # Inicializar algumas variáveis auxiliares
            path=0;
            space_b=0;
            final_space_files=()
            # Preenchimento do array storage com todos os ficheiros e sub-diretorias de uma diretoria, 
            # ordenados por ordem decrescente de tamanho
            storage=($( ls -l $i 2>/dev/null | sort -nr | awk '{print $9}'))

            for j in "${storage[@]}"
            do
                # Se $j for um ficheiro
                path="$i/$j"
                if [ -f $path ]; then
                    # Verificar se estamos na presença de um ficheiro essencial
                    if ( $opt_e ); then
                        ignore_file=false
                        for f in ${essential_files[@]}
                        do
                            if [[ $j =~ "$f" ]]; then
                                ignore_file=true 
                            fi
                        done
                        if ( $ignore_file ); then 
                            # Caso seja um ficheiro essencial, ignorá-lo e passar para o seguinte
                            continue 
                        fi
                    fi

                    # Obter o espaço ocupado por um ficheiro
                    space=$(ls -l ${path}  2>/dev/null | awk '{print $5}')
            
                     # Obter a última data de acesso ao ficheiro no formato AnoMêsDiaHoraMinuto
                    file_date=$(stat $path | tail -4 | head -1 | awk '{print $2, $3}')
                    file_date=$(date -d $file_date "+%Y%m%d%H%M")

                    # Opções -n e -d passadas na liha de comandos
                    if [ $opt_n = true -a $opt_d = true ]; then
                        if [[ $file_date -le $opt_d_arg && $path =~ "$opt_n_arg" ]]; then
                            final_space_files+=( "${space} " )
                        fi
                    # Opção -n passada na linha de comandos
                    elif [ $opt_n = true ]; then
                        if [[ $path =~ "$opt_n_arg" ]];then
                            final_space_files+=( "${space} " )
                        fi
                    # Opção -d passada na linha de comandos
                    elif [ $opt_d = true ]; then
                        if [ $file_date -le $opt_d_arg ]; then
                            final_space_files+=( "${space} " )
                        fi 
                    # Opções -n e -d ausentes na liha de comandos
                    else
                        final_space_files+=( "${space} " )
                    fi
                fi
            done

            # Colocar no main_dictionary os $opt_l_arg maiores ficheiros e respetivos tamanhos
            final_space_files=( $( printf "%s\n" "${final_space_files[@]}" | sort -nr | head -${opt_l_arg} ) )
            for k in "${final_space_files[@]}"
            do
                space_b=$((space_b + k));
            done
            main_dictionary["${i}"]="${space_b}"
        done  
    fi
    
    # Considerar apenas os $opt_L_arg maiores ficheiros de cada diretoria 
    if [ $opt_L = true ];then
        for k in "${!file_dictionary[@]}"
        do
            echo ${file_dictionary["$k"]} $k 
        done | sort -rn -k1 | head -${opt_L_arg}
    else
        # Imprimir todos as diretorias encontradas e respetivos tamanhos
        for i in "${!main_dictionary[@]}"
        do  
            # Variável que irá armazenar o tamanho do diretório
            final_space=0;
            # Array de todos os sub-diretórios de um diretório
            diretorios=($( ls -lhR $i 2>/dev/null | grep '/' ))
            for j in "${diretorios[@]}"
            do
                j=${j%?}
                final_space=$((main_dictionary[$j] + final_space)) 
            done
            if [ "$final_space" -eq "0" ];then
                echo "NA $i"
            else
                echo "$final_space $i"
            fi
        done 
    fi
}

# 2.3 - Função main()
# Sempre que é chamada para cada uma das diretorias passadas na linha de comandos, esta função inicializa
# todas as variáveis necessárias para a procura de sub-diretorias e ficheiros, calculando os seus respetivos
# tamanhos e imprimindo os resultados obtidos no terminal
function main() {
    
    # Array associativo para guardar todas diretorias e respetivos tamanhos
    declare -A main_dictionary      

    # Array associativo para guardar todos os ficheiros e respetivos tamanhos
    declare -A file_dictionary      

    # Array auxiliar que irá guardar todos as diretorias
    path_array=(${1})
    
    # Array auxiliar que irá guardar todos os tamanhos das diretorias
    size_array=()

    # Chamada da função recursiva showFiles, levando a diretoria passada na linha de comandos como argumento
    showFiles "$1"

    # Adicionar ao array de tamanhos o tamanho da diretoria passada na linha de comandos
    size_array+=("${total_space}") 

    # Preenchimento do main_dictionary com as diretorias e respetivos tamanhos calculados
    counter=0;
    for i in "${path_array[@]}"
    do
        main_dictionary["${i}"]="${size_array[$counter]}"
        counter=$((counter + 1));
    done
    
    # Chamada da função print()
    print
}

##############################################################################################
# 3 - INÍCIO DA PROCURA DE SUB-DIRETORIAS DE TODAS AS DIRETORIAS PASSADAS NA LINHA DE COMANDOS
##############################################################################################
for i in $@
do
    main $i
done |  if [ "$opt_r" = true -a "$opt_a" = false ]; then    # -r: ordenação numérica e decrescente
            sort -nr 
        elif [ "$opt_a" = true -a "$opt_r" = false ]; then  # -a: ordenação alfabética e crescente (de A até Z)
            sort -k2 
        elif [ "$opt_r" = true -a "$opt_a" = true ]; then   # -a && -r: ordenação alfabética e decrescente (de Z até A)
            sort -k2r
        else                                                # Default: ordenação numérica e crescente
            sort -n                                         
        fi  
##############################################################################################
# FINAL DO SCRIPT NESPACE.SH
##############################################################################################