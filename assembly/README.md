# Projeto Assembly de Microcontroladores
## Elevador de 3 andares

## **Objetivo**

Implementar em assembly do AVR um código que simule o funcionamento de um elevador para um prédio de 3 andares (térreo + 3).

## **Equipamentos**

- 1x Display 7 segmentos para mostrar onde está o elevador
- 4x Botão para chamar elevador (botão nos andares)
- 4x botões para definir para qual andar ir (botão dentro do elevador)
- 1x botão para abrir a porta
- 1x botão para fechar a porta
- 1x Buzzer para avisar que a porta esta aberta
- 1x Led verde para indicar abertura da porta

## **Simulação dos equipamentos:**

- Display de 7 segmentos deverá ser simulado como um valor em um registrador.
- Botão, Buzzer e Led deverão ser simulado como um bit em uma das portas de E/S.

## **Requisitos**
- Priorizar os andares mais altos caso tenha duas chamadas

Exemplo: Se estiver no térreo subindo para o 2º andar, não deve parar no 1º andar, mesmo que o botão que fica no primeiro andar tenha sido pressionado antes de o carro do elevador passar pelo 1° andar.

**Obs:** Essa prioridade não acontece para os botões dentro do elevador.

- Se a porta do elevador ficar aberta por 5 microssegundos, toca-se o Buzzer 
- Se a porta do elevador ficar aberta por 10 microssegundos, deve ser fechada
- O elevador leva 10 microssegundos   de um andar para o outro
- Deve-se utilizar os Timers do AVR para definir os tempos. Deve-se utilizar interrupção ao invés de verificação de flag

Obs: Esse tempo de microssegundos é para facilitar a simulação, não é um tempo prático.
