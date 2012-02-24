package Spaghetti::I18N::ru;
use base 'Spaghetti::I18N';
use Pony::View::Form::Translate;
use Encode 'decode';

our %Lexicon = (
    _AUTO => 1,
    'Repo'          => 'Репозиторий',
    'Repos'         => 'Репозитории',
    'New repo'      => 'Создать новый',
    'Add key'       => 'Добавить ключ',
    'name'          => 'имя',
    'members'       => 'пользователи',
    'description'   => 'описание',
    'password'      => 'пароль',
    'repeat'        => 'повторить',
    'registered'    => 'зарегистрирован',
    'Register'      => 'Регистрация',
    'ban reason'    => 'причина блокировки',
    'ban time'      => 'время блокировки',
    'now'           => 'сейчас',
    'Add'           => 'Добавить',
    'status'        => 'статус',
    'active'        => 'активный',
    'inactive'      => 'деактивирован',
    'week'          => 'неделя',
    'day'           => 'день',
    'hour'          => 'час',
    'edit'          => 'изменить',
    'delete'        => 'удалить',
    'description'   => 'описание',
   
    'ban options'   => 'блокировка',
    
    'Profile'       => 'Профиль',
    'Login'         => 'Войти',
    'Login via mail'=> 'Войти с почты',
    'Logout'        => 'Выйти',
    
    'Add server'    => 'Добавить сервер',
    
    'index'         => 'Главная',
    
    'mins1'         => 'минуту',
    'mins2'         => 'минуты',
    'mins5'         => 'минут',
    
    'hours1'        => 'час',
    'hours2'        => 'часа',
    'hours5'        => 'часов',
    
    'ago'           => 'назад',
    'createAt'      => 'время создания',
    'modifyAt'      => 'время изменения',
    'accessAt'      => 'последнее посещение',
    
    'Users'         => 'Пользователи',
    'Threads'       => 'Треды',
    'Groups'        => 'Группы',
    'Types'         => 'Типы данных',
    'Configure user'=> 'Настройка пользователя',
    
    'a few seconds ago' => 'несколько секунд назад',
    'Your public key'   => 'Ваш публичный ключ',
    'Create new repo'   => 'Создать новый репозиторий',
    'Repository list'   => 'Список репозиториев',
    'change password'   => 'сменить пароль',
    'How to create new repository' => 'Как создать новый репозиторий',
    'Add server public key'        => 'Добавить публичный ключ сервера',
    'This page does not exist or you can\'t read it.' => 'Эта страница не существует, или у Вас не хватает прав.',
    
    'Forum'             => 'Форум',
    'Admin panel'       => 'Администрировать',
    'User list'         => 'Список пользователей',
    'Thread list'       => 'Список тредов',
    'Group list'        => 'Список групп',
    'Thread type list'  => 'Список типов тредов',
    'Data type list'    => 'Список типов данных',

    'response'          => 'ответить',
    'create topic'      => 'создать тему',
    'hide'              => 'скрыть',
    'Edit post'         => 'Редактировать',
    'Go to thread'      => 'Перейти к треду',
    'mail'              => 'E-mail',
    'banTime'           => 'время блокирования',
    'never'             => 'никогда',
    'add'               => 'добавить',
    'remove'            => 'убрать',
    'Delete user'       => 'Удалить пользователя',
    'Add root thread'   => 'Добавить корневой тред',
    'Create new topic'  => 'Создать новую тему',
    'Add new'           => 'Добавить ещё',
    'prioritet'         => 'приоритет',
    'rights'            => 'права',
    'Send'              => 'Отправить',
    'Password'          => 'Пароль',
    'Registration'      => 'Регистрация',
    'Data type'         => 'Тип данных',
    'Topic'             => 'Тема',
    'Size'              => 'Размер',
    'Time'              => 'Время',
    'Tracker'           => 'Трекер',
    'Login via mail'    => 'Войти через почту',
    'Responses to'      => 'Ответы на',
    'News list'         => 'Новости',
    'logout'            => 'Выйти',
    'Description'       => 'Описание',
    'Change password'   => 'Изменить пароль',
    'Change mail'       => 'Изменить почту',
    'Prioritet'         => 'Приоритет',
    'Create new group'  => 'Создать новую группу',
    'Private thread'    => 'Личная страница',
    'personal thread'   => 'личная страница',
    'Config'            => 'Настройка',
    'make news'         => 'Создать новость',
    'Tree view'         => 'Комментарии в виде дерева',
    'Create news from topic'        => 'Создать новость из темы',
    'You have a response in topic'  => 'Вы получили ответ в теме',
    'Check your mail'               => 'Проверьте Вашу почту',
    'Create private thread'         => 'Создать личную страницу',
    'You have a response to'        => 'Вы получили ответ на',
    'Create new data type'          => 'Создать новый тип данных',
    'Configure special params for'  => 'Настройка специальных параметров для',
    'Yes, I want to exit from this site' => 'Да, я хочу выйти из этого сайта',
    'You have not rights to do it'  => 'У Вас не хватает прав, чтобы совершить это действие',
    'The data, which you send us, is not valid or not actual' => 'Данные, которые вы отправили, не верны или устарели.'
);

$Lexicon{$_} = decode('utf8', $Lexicon{$_}) for keys %Lexicon;

my $t = new Pony::View::Form::Translate('ru');
$t->Lexicon->{ru} = 
    {
        'Value must have %s like %s'        => 'Значение должно содержать %s, например, %s',
        'latin chars in lower case'         => 'латинские символы в нижнем регистре',
        'latin chars in upper case'         => 'латинские символы в верхнем регистре',
        'Length must be between %d and %d'  => 'Длина должна быть между %d и %d',
        'Does not valid required format'    => 'Неправильный формат',
        'Invalid mail or password'          => 'Неправильный E-mail или пароль',
        'Too much login attempts'           => 'Слишком много неудачных попыток входа',
        'special chars' => 'специальные символы',
        'digits'        => 'цифры',
        'Password'      => 'Пароль',
        'Name'          => 'Имя',
        'Visible'       => 'Показать',
        'I`m not bot'   => 'He бoт',
        'Old password'  => 'Старый',
        'New password'  => 'Новый',
        'Title'         => 'Заголовок',
        'Legend'        => 'Описание',
        'Text'          => 'Текст',
        'Parent'        => 'Родитель',
        'Topic'         => 'Тема',
        'Flush password'    => 'Сбросить',
        'Generate password' => 'Сгенерировать',
    };

$t->Lexicon->{ru}->{$_} =
        decode('utf8', $t->Lexicon->{ru}->{$_}) for keys %{ $t->Lexicon->{ru} };

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 - 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

