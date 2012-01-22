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
    
    'a few seconds ago' => 'несколько секунд назад',
    'Your public key'   => 'Ваш публичный ключ',
    'Create new repo'   => 'Создать новый репозиторий',
    'Repository list'   => 'Список репозиториев',
    'change password'   => 'сменить пароль',
    'How to create new repository' => 'Как создать новый репозиторий',
    'Add server public key'        => 'Добавить публичный ключ сервера',
    'This page does not exist or you can\'t read it.' => 'Эта страница не существует, или у Вас не хватает прав.',
    
    'Forum'         => 'Форум',
    'Admin panel'   => 'Администрировать',
    'User list'     => 'Список пользователей',
    'Thread list'   => 'Список тредов',
    'Group list'    => 'Список групп',
    'Thread type list'  => 'Список типов тредов',
    'Data type list'=> 'Список типов данных',

    'response'      => 'ответить',
    'create topic'  => 'создать тему',
    'hide'          => 'скрыть',
    'Edit post'     => 'Редактировать',
    'Go to thread'  => 'Перейти к треду',
    'mail'          => 'E-mail',
    'banTime'       => 'время блокирования',
    'never'         => 'никогда',
    'add'           => 'добавить',
    'remove'        => 'убрать',
    'Delete user'   => 'Удалить пользователя',
    'Add root thread'   => 'Добавить корневой тред',
    'Create new topic'  => 'Создать новую тему',
    'Add new'       => 'Добавить ещё',
    'prioritet'     => 'приоритет',
    'rights'        => 'права',
    'Send'          => 'Отправить',
    'Password'      => 'Пароль',
    'Registration'  => 'Регистрация',
    'Create new data type'  => 'Создать новый тип данных',
    'Data type'     => 'Тип данных',
    'Configure special params for' => 'Настройка специальных параметров для',
    'Topic'         => 'Тема',
    'Size'          => 'Размер',
    'Time'          => 'Время',
    'Tracker'       => 'Трекер',
    'Login via mail'=> 'Войти через почту',
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

